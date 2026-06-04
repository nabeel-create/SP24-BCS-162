"""
nabeel — Production-Grade ArcFace Recognition Service v2
========================================================
Model  : ArcFace (512-dim) via DeepFace — highest accuracy
Detector: retinaface (best) with opencv fallback
Extras : face verification · face analysis · batch recognition
         quality scoring · model warmup · performance metrics

Routes (all under /nabeel):
  GET  /nabeel/health
  GET  /nabeel/metrics
  POST /nabeel/extract-embedding
  POST /nabeel/verify              (1-to-1 face comparison)
  POST /nabeel/recognize           (1-to-N search)
  POST /nabeel/recognize/batch     (multiple frames at once)
  POST /nabeel/analyze             (age · gender · emotion · race)
  GET  /nabeel/docs
"""

import os, base64, io, time, logging, threading
from typing import List, Optional, Dict, Any
from collections import defaultdict
from dataclasses import dataclass, field

import numpy as np
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)
logger = logging.getLogger("nabeel")

# ── FastAPI app ───────────────────────────────────────────────────────────────
app = FastAPI(
    title="nabeel — ArcFace Recognition API",
    description=(
        "Production-grade face recognition powered by **ArcFace** (512-dim embeddings).\n\n"
        "Endpoints: extract embedding · 1-to-1 verify · 1-to-N recognize · face analysis."
    ),
    version="2.0.0",
    docs_url="/nabeel/docs",
    redoc_url="/nabeel/redoc",
    openapi_url="/nabeel/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Config ────────────────────────────────────────────────────────────────────
MODEL             = "ArcFace"       # 512-dim — state-of-the-art accuracy
DETECTOR_PRIMARY  = "mtcnn"         # top accuracy, pure-python, no libGL needed
DETECTOR_FALLBACK = "opencv"        # fast CPU fallback
COSINE_THRESHOLD  = 0.40            # ArcFace sweet-spot (0.30 strict / 0.50 lenient)
QUALITY_THRESHOLD = 0.25            # min face quality score (0-1)
MAX_BATCH_FRAMES  = 10              # max frames per batch request
MAX_FACES_PER_FRAME = 20            # safety cap


# ── Metrics ───────────────────────────────────────────────────────────────────
@dataclass
class _Metrics:
    start_time: float = field(default_factory=time.time)
    requests: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    latencies: Dict[str, List[float]] = field(default_factory=lambda: defaultdict(list))
    errors: int = 0
    faces_processed: int = 0
    faces_recognized: int = 0

    def record(self, endpoint: str, latency_ms: float, faces: int = 0, matched: int = 0):
        self.requests[endpoint] += 1
        self.latencies[endpoint].append(latency_ms)
        self.faces_processed += faces
        self.faces_recognized += matched

    def summary(self) -> dict:
        uptime = time.time() - self.start_time
        avg_lat = {
            ep: round(sum(v) / len(v), 1) if v else 0
            for ep, v in self.latencies.items()
        }
        return {
            "uptime_seconds": round(uptime, 1),
            "requests": dict(self.requests),
            "avg_latency_ms": avg_lat,
            "errors": self.errors,
            "faces_processed": self.faces_processed,
            "faces_recognized": self.faces_recognized,
        }

_metrics = _Metrics()


# ── Model registry ────────────────────────────────────────────────────────────
class _ModelState:
    ready   : bool   = False
    detector: str    = DETECTOR_PRIMARY
    error   : Optional[str] = None
    load_time_s: float = 0.0

_state = _ModelState()

def _warm_up():
    """Load and warm up DeepFace + ArcFace weights in a background thread."""
    t0 = time.time()
    try:
        from deepface import DeepFace
        import numpy as np
        dummy = np.zeros((160, 160, 3), dtype=np.uint8)
        # Trigger primary detector
        try:
            DeepFace.represent(dummy, model_name=MODEL,
                               detector_backend=DETECTOR_PRIMARY,
                               enforce_detection=False, align=True)
            _state.detector = DETECTOR_PRIMARY
            logger.info("retinaface detector loaded ✓")
        except Exception as e:
            logger.warning("retinaface unavailable (%s) — falling back to opencv", e)
            DeepFace.represent(dummy, model_name=MODEL,
                               detector_backend=DETECTOR_FALLBACK,
                               enforce_detection=False, align=True)
            _state.detector = DETECTOR_FALLBACK

        _state.ready      = True
        _state.load_time_s = round(time.time() - t0, 1)
        logger.info("✓ ArcFace model ready in %.1f s (detector=%s)", _state.load_time_s, _state.detector)
    except Exception as exc:
        _state.error = str(exc)
        logger.error("Model warm-up failed: %s", exc)

@app.on_event("startup")
def startup():
    threading.Thread(target=_warm_up, daemon=True).start()
    logger.info("nabeel v2 starting — model warming up in background …")


# ── Image helpers ─────────────────────────────────────────────────────────────
def decode_image(b64: str) -> np.ndarray:
    from PIL import Image
    if "," in b64:
        b64 = b64.split(",", 1)[1]
    try:
        raw = base64.b64decode(b64)
        img = Image.open(io.BytesIO(raw)).convert("RGB")
        return np.array(img)
    except Exception as exc:
        raise ValueError(f"Cannot decode image: {exc}") from exc


def cosine_distance(a: List[float], b: List[float]) -> float:
    va = np.array(a, dtype=np.float64)
    vb = np.array(b, dtype=np.float64)
    na, nb = np.linalg.norm(va), np.linalg.norm(vb)
    if na == 0 or nb == 0:
        return 1.0
    return float(1.0 - np.dot(va, vb) / (na * nb))


def get_deepface():
    from deepface import DeepFace
    return DeepFace


def _represent(img: np.ndarray, enforce: bool = True) -> List[Dict]:
    """Run DeepFace.represent with detector auto-fallback."""
    df = get_deepface()
    try:
        return df.represent(img_path=img, model_name=MODEL,
                            detector_backend=_state.detector,
                            enforce_detection=enforce, align=True)
    except Exception:
        if _state.detector != DETECTOR_FALLBACK:
            return df.represent(img_path=img, model_name=MODEL,
                                detector_backend=DETECTOR_FALLBACK,
                                enforce_detection=enforce, align=True)
        raise


def confidence_from_distance(dist: float, threshold: float) -> float:
    """Map cosine distance to 0-100 confidence; 100 = perfect match."""
    if threshold <= 0:
        return 0.0
    raw = 1.0 - (dist / threshold)
    return round(max(0.0, min(100.0, raw * 100)), 1)


def face_quality(face_obj: dict) -> float:
    """
    Estimate face quality 0-1 from facial area size.
    Larger aligned faces → higher quality.
    """
    area = face_obj.get("facial_area", {})
    if not area:
        return 0.5
    w = area.get("w", 0)
    h = area.get("h", 0)
    score = min(1.0, (w * h) / (150 * 150))
    return round(score, 3)


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class ExtractRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 image (JPEG/PNG) or data-URI")
    enforce_detection: bool = Field(True, description="Raise error if no face found")
    min_quality: float = Field(0.0, ge=0, le=1,
                               description="Skip low-quality detections (0 = disabled)")

class EmbeddingResult(BaseModel):
    embedding: Optional[List[float]] = None
    quality_score: float = 0.0
    success: bool
    message: str = ""
    model: str = MODEL
    dim: int = 0

class ExtractResponse(BaseModel):
    results: List[EmbeddingResult]   # one per face detected
    total_faces: int
    latency_ms: float


class VerifyRequest(BaseModel):
    image1_base64: str
    image2_base64: str
    threshold: Optional[float] = Field(None, ge=0.1, le=1.0)

class VerifyResponse(BaseModel):
    verified: bool
    distance: float
    confidence_pct: float
    threshold_used: float
    latency_ms: float


class EnrolledFace(BaseModel):
    student_id: int
    student_name: str
    embeddings: List[List[float]] = Field(..., min_length=1,
        description="1+ embeddings per person (more angles = better accuracy)")

    @field_validator("embeddings")
    @classmethod
    def check_dim(cls, v):
        for emb in v:
            if len(emb) != 512:
                raise ValueError(f"Expected 512-dim ArcFace embedding, got {len(emb)}")
        return v

class RecognizeRequest(BaseModel):
    image_base64: str
    enrolled_faces: List[EnrolledFace]
    threshold: Optional[float] = Field(None, ge=0.1, le=1.0)
    max_faces: int = Field(MAX_FACES_PER_FRAME, ge=1, le=MAX_FACES_PER_FRAME)
    min_quality: float = Field(0.0, ge=0, le=1)

class RecognizedFace(BaseModel):
    student_id: int
    student_name: str
    distance: float
    confidence_pct: float
    quality_score: float
    face_index: int          # which detected face (0-indexed)

class RecognizeResponse(BaseModel):
    recognized: List[RecognizedFace]
    unrecognized_faces: int  # detected but not matched
    total_faces_detected: int
    threshold_used: float
    latency_ms: float


class BatchRecognizeRequest(BaseModel):
    frames: List[str] = Field(..., max_length=MAX_BATCH_FRAMES,
                              description="List of base64 image frames")
    enrolled_faces: List[EnrolledFace]
    threshold: Optional[float] = Field(None, ge=0.1, le=1.0)

class BatchFrameResult(BaseModel):
    frame_index: int
    recognized: List[RecognizedFace]
    total_faces_detected: int
    latency_ms: float

class BatchRecognizeResponse(BaseModel):
    frames: List[BatchFrameResult]
    total_recognized_unique: int
    total_latency_ms: float


class AnalyzeRequest(BaseModel):
    image_base64: str
    actions: List[str] = Field(
        ["age", "gender", "emotion"],
        description="age · gender · emotion · race"
    )

class FaceAnalysis(BaseModel):
    age: Optional[int] = None
    gender: Optional[str] = None
    dominant_emotion: Optional[str] = None
    dominant_race: Optional[str] = None
    emotions: Optional[Dict[str, float]] = None
    region: Optional[Dict[str, int]] = None

class AnalyzeResponse(BaseModel):
    faces: List[FaceAnalysis]
    total_faces: int
    latency_ms: float


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/nabeel/health", tags=["System"])
def health():
    return {
        "status": "ok" if _state.ready else "warming_up",
        "service": "nabeel",
        "version": "2.0.0",
        "model": MODEL,
        "detector": _state.detector,
        "model_ready": _state.ready,
        "model_load_time_s": _state.load_time_s,
        "warmup_error": _state.error,
        "default_threshold": COSINE_THRESHOLD,
        "embedding_dim": 512,
    }


@app.get("/nabeel/metrics", tags=["System"])
def metrics():
    return {"service": "nabeel", **_metrics.summary()}


@app.post("/nabeel/extract-embedding", response_model=ExtractResponse, tags=["Core"])
def extract_embedding(req: ExtractRequest):
    """
    Extract one ArcFace embedding per face found in the image.

    **Best practice for enrolment:**
    - Send 3-5 photos per person (frontal, slight left/right turns, smile)
    - Store **all** returned embeddings — the recognize endpoint uses
      minimum distance across all stored embeddings.
    """
    t0 = time.perf_counter()
    try:
        img = decode_image(req.image_base64)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc

    try:
        face_objs = _represent(img, enforce=req.enforce_detection)
    except Exception as exc:
        logger.info("No faces detected: %s", exc)
        face_objs = []

    results: List[EmbeddingResult] = []
    for fo in face_objs:
        emb = fo.get("embedding", [])
        q   = face_quality(fo)
        if req.min_quality > 0 and q < req.min_quality:
            results.append(EmbeddingResult(
                success=False, quality_score=q, dim=len(emb),
                message=f"Face quality {q:.2f} < min_quality {req.min_quality:.2f}",
            ))
            continue
        results.append(EmbeddingResult(
            embedding=emb, quality_score=q,
            success=bool(emb), dim=len(emb),
            message="OK" if emb else "No embedding returned",
        ))

    if not results:
        results.append(EmbeddingResult(
            success=False, message="No face detected — try a clearer, well-lit photo"))

    lat = round((time.perf_counter() - t0) * 1000, 1)
    _metrics.record("extract", lat, faces=len(results))
    return ExtractResponse(results=results, total_faces=len(results), latency_ms=lat)


@app.post("/nabeel/verify", response_model=VerifyResponse, tags=["Core"])
def verify_faces(req: VerifyRequest):
    """
    **1-to-1 face verification** — are these two images the same person?

    Returns `verified=true` when cosine distance ≤ threshold.
    Useful for login / identity confirmation flows.
    """
    t0 = time.perf_counter()
    threshold = req.threshold if req.threshold is not None else COSINE_THRESHOLD

    def get_emb(b64: str, label: str) -> List[float]:
        img = decode_image(b64)
        try:
            objs = _represent(img, enforce=True)
            if objs:
                return objs[0]["embedding"]
        except Exception as exc:
            raise HTTPException(400, f"No face found in {label}: {exc}") from exc
        raise HTTPException(400, f"No face found in {label}")

    try:
        emb1 = get_emb(req.image1_base64, "image1")
        emb2 = get_emb(req.image2_base64, "image2")
    except HTTPException:
        _metrics.errors += 1
        raise

    dist    = cosine_distance(emb1, emb2)
    conf    = confidence_from_distance(dist, threshold)
    lat     = round((time.perf_counter() - t0) * 1000, 1)
    matched = dist <= threshold

    logger.info("verify → dist=%.4f  conf=%.1f%%  matched=%s", dist, conf, matched)
    _metrics.record("verify", lat, faces=2, matched=int(matched))
    return VerifyResponse(
        verified=matched, distance=round(dist, 4),
        confidence_pct=conf, threshold_used=threshold, latency_ms=lat,
    )


@app.post("/nabeel/recognize", response_model=RecognizeResponse, tags=["Core"])
def recognize_faces(req: RecognizeRequest):
    """
    **1-to-N recognition** — detect every face in an image and match against DB.

    Each enrolled person is matched at most once per frame.
    Supply multiple embeddings per person for best accuracy.
    """
    t0 = time.perf_counter()
    threshold = req.threshold if req.threshold is not None else COSINE_THRESHOLD

    if not req.enrolled_faces:
        return RecognizeResponse(
            recognized=[], unrecognized_faces=0, total_faces_detected=0,
            threshold_used=threshold, latency_ms=0.0,
        )

    try:
        img = decode_image(req.image_base64)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc

    try:
        face_objs = _represent(img, enforce=True)
    except Exception as exc:
        logger.info("No faces in frame: %s", exc)
        lat = round((time.perf_counter() - t0) * 1000, 1)
        return RecognizeResponse(
            recognized=[], unrecognized_faces=0, total_faces_detected=0,
            threshold_used=threshold, latency_ms=lat,
        )

    face_objs = face_objs[: req.max_faces]
    recognized: List[RecognizedFace] = []
    matched_ids: set = set()
    unrecognized = 0

    for idx, face_obj in enumerate(face_objs):
        query_emb = face_obj.get("embedding", [])
        if not query_emb:
            continue
        q_score    = face_quality(face_obj)
        if req.min_quality > 0 and q_score < req.min_quality:
            unrecognized += 1
            continue

        best_dist  = float("inf")
        best_match: Optional[EnrolledFace] = None

        for enrolled in req.enrolled_faces:
            if enrolled.student_id in matched_ids:
                continue
            for stored_emb in enrolled.embeddings:
                if len(stored_emb) != len(query_emb):
                    continue
                d = cosine_distance(query_emb, stored_emb)
                if d < best_dist:
                    best_dist, best_match = d, enrolled

        if best_match and best_dist <= threshold:
            matched_ids.add(best_match.student_id)
            conf = confidence_from_distance(best_dist, threshold)
            recognized.append(RecognizedFace(
                student_id=best_match.student_id,
                student_name=best_match.student_name,
                distance=round(best_dist, 4),
                confidence_pct=conf,
                quality_score=q_score,
                face_index=idx,
            ))
            logger.info("✓ %s  dist=%.4f  conf=%.1f%%  quality=%.2f",
                        best_match.student_name, best_dist, conf, q_score)
        else:
            unrecognized += 1
            logger.info("✗ unknown  dist=%.4f  quality=%.2f", best_dist, q_score)

    lat = round((time.perf_counter() - t0) * 1000, 1)
    _metrics.record("recognize", lat, faces=len(face_objs), matched=len(recognized))
    return RecognizeResponse(
        recognized=recognized,
        unrecognized_faces=unrecognized,
        total_faces_detected=len(face_objs),
        threshold_used=threshold,
        latency_ms=lat,
    )


@app.post("/nabeel/recognize/batch", response_model=BatchRecognizeResponse, tags=["Core"])
def recognize_batch(req: BatchRecognizeRequest):
    """
    Process **multiple frames at once** — ideal for video attendance or burst photos.
    Up to 10 frames per request.
    """
    t_all = time.perf_counter()
    threshold = req.threshold if req.threshold is not None else COSINE_THRESHOLD
    frame_results: List[BatchFrameResult] = []
    all_ids: set = set()

    for fi, frame_b64 in enumerate(req.frames):
        t0 = time.perf_counter()
        try:
            img = decode_image(frame_b64)
        except ValueError:
            frame_results.append(BatchFrameResult(
                frame_index=fi, recognized=[], total_faces_detected=0,
                latency_ms=0.0,
            ))
            continue

        try:
            face_objs = _represent(img, enforce=True)
        except Exception:
            face_objs = []

        recognized: List[RecognizedFace] = []
        matched_in_frame: set = set()

        for idx, face_obj in enumerate(face_objs[:MAX_FACES_PER_FRAME]):
            query_emb = face_obj.get("embedding", [])
            if not query_emb:
                continue
            best_dist  = float("inf")
            best_match = None
            for enrolled in req.enrolled_faces:
                if enrolled.student_id in matched_in_frame:
                    continue
                for stored_emb in enrolled.embeddings:
                    if len(stored_emb) != len(query_emb):
                        continue
                    d = cosine_distance(query_emb, stored_emb)
                    if d < best_dist:
                        best_dist, best_match = d, enrolled
            if best_match and best_dist <= threshold:
                matched_in_frame.add(best_match.student_id)
                all_ids.add(best_match.student_id)
                recognized.append(RecognizedFace(
                    student_id=best_match.student_id,
                    student_name=best_match.student_name,
                    distance=round(best_dist, 4),
                    confidence_pct=confidence_from_distance(best_dist, threshold),
                    quality_score=face_quality(face_obj),
                    face_index=idx,
                ))

        lat = round((time.perf_counter() - t0) * 1000, 1)
        frame_results.append(BatchFrameResult(
            frame_index=fi, recognized=recognized,
            total_faces_detected=len(face_objs), latency_ms=lat,
        ))

    total_lat = round((time.perf_counter() - t_all) * 1000, 1)
    _metrics.record("batch", total_lat)
    return BatchRecognizeResponse(
        frames=frame_results,
        total_recognized_unique=len(all_ids),
        total_latency_ms=total_lat,
    )


@app.post("/nabeel/analyze", response_model=AnalyzeResponse, tags=["Extras"])
def analyze_faces(req: AnalyzeRequest):
    """
    **Face analysis** — run age · gender · emotion · race on every face in the image.
    Select which analyses to run via the `actions` field to save time.
    """
    t0 = time.perf_counter()
    valid_actions = {"age", "gender", "emotion", "race"}
    actions = [a for a in req.actions if a in valid_actions] or ["age", "gender", "emotion"]

    try:
        img = decode_image(req.image_base64)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc

    df = get_deepface()
    try:
        objs = df.analyze(
            img_path=img,
            actions=actions,
            detector_backend=_state.detector,
            enforce_detection=True,
            align=True,
        )
    except Exception as exc:
        logger.info("analyze: no face — %s", exc)
        objs = []

    faces: List[FaceAnalysis] = []
    for obj in (objs if isinstance(objs, list) else [objs]):
        emotions: Optional[Dict[str, float]] = None
        if "emotion" in actions:
            raw_em = obj.get("emotion", {})
            emotions = {k: round(float(v), 2) for k, v in raw_em.items()}

        faces.append(FaceAnalysis(
            age=int(obj["age"]) if "age" in obj else None,
            gender=str(obj.get("dominant_gender", "")) or None,
            dominant_emotion=str(obj.get("dominant_emotion", "")) or None,
            dominant_race=str(obj.get("dominant_race", "")) or None,
            emotions=emotions,
            region=obj.get("region"),
        ))

    lat = round((time.perf_counter() - t0) * 1000, 1)
    _metrics.record("analyze", lat, faces=len(faces))
    return AnalyzeResponse(faces=faces, total_faces=len(faces), latency_ms=lat)


# ── Error handlers ────────────────────────────────────────────────────────────
@app.exception_handler(Exception)
async def global_handler(request, exc):
    _metrics.errors += 1
    logger.error("Unhandled error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})


# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    logger.info("nabeel v2 → port %d", port)
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=False,
        log_level="info",
        access_log=True,
    )
