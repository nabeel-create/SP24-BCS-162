# nabeel — ArcFace Recognition Service

Python FastAPI service using **DeepFace + ArcFace** for high-accuracy face recognition.

## Base path

All routes are served under `/nabeel/`:

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/nabeel/health` | Health check + model status |
| `POST` | `/nabeel/extract-embedding` | Enrol a face → get 512-dim embedding |
| `POST` | `/nabeel/recognize` | Match faces in a photo against enrolled database |
| `GET` | `/nabeel/docs` | Interactive Swagger UI |

## How it works

```
Enrolment
  Take 3-5 photos of each person → POST /extract-embedding each one
  → store all returned embeddings with the person's ID + name

Recognition
  Take a group photo → POST /recognize with the stored embeddings
  → get back matched student IDs, names, distances, confidence %
```

## API shapes

### POST /nabeel/extract-embedding

```json
{
  "image_base64": "<base64 or data-URI of the face image>"
}
```

Response:
```json
{
  "success": true,
  "embedding": [0.12, -0.34, ...],   // 512 floats
  "message": "Embedding extracted successfully"
}
```

### POST /nabeel/recognize

```json
{
  "image_base64": "<base64 of the group photo>",
  "threshold": 0.40,
  "enrolled_faces": [
    {
      "student_id": 1,
      "student_name": "Nabeel Khan",
      "embeddings": [
        [0.12, -0.34, ...],
        [0.15, -0.31, ...]
      ]
    }
  ]
}
```

Response:
```json
{
  "recognized": [
    {
      "student_id": 1,
      "student_name": "Nabeel Khan",
      "distance": 0.2341,
      "confidence_pct": 41.5
    }
  ],
  "total_faces_detected": 3,
  "threshold_used": 0.40
}
```

## Threshold guide

| `threshold` | Behaviour |
|-------------|-----------|
| `0.30` | Very strict — fewer false positives |
| **`0.40`** | **Default — best balance** |
| `0.50` | More lenient — fewer false negatives |

## First-run note

On the **first request** the service downloads the ArcFace model weights (~100 MB).
This takes ~30 seconds. Subsequent requests are fast. The `/health` endpoint
shows `"model_ready": true` once the download is complete.
