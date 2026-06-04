import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/face_api_service.dart';
import '../../theme/app_colors.dart';

class FaceRegisterScreen extends StatefulWidget {
  final Student student;
  const FaceRegisterScreen({super.key, required this.student});
  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  bool _camReady = false;
  bool _capturing = false;
  bool _saving = false;
  List<List<double>> _collected = [];
  String _instruction = 'Look straight at the camera';

  final _angles = [
    'Look straight at the camera',
    'Slowly turn slightly left',
    'Slowly turn slightly right',
    'Tilt your head slightly up',
    'Tilt your head slightly down',
  ];

  @override
  void initState() { super.initState(); _initCamera(); }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      final front = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _cam = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (e) {
      if (mounted) setState(() => _instruction = 'Camera unavailable: $e');
    }
  }

  @override
  void dispose() { _cam?.dispose(); super.dispose(); }

  Future<void> _captureAngle() async {
    if (_cam == null || !_camReady || _capturing) return;
    final angleIdx = _collected.length;
    if (angleIdx >= _angles.length) return;
    setState(() { _capturing = true; _instruction = 'Hold still…'; });
    try {
      final photo = await _cam!.takePicture();
      final bytes = await photo.readAsBytes();
      final b64 = base64Encode(bytes);
      final embedding = await FaceApiService.instance.extractEmbedding(b64);
      if (embedding == null) {
        setState(() { _instruction = 'No face detected. Try again.'; });
      } else {
        _collected.add(embedding);
        final next = _collected.length;
        setState(() {
          _instruction = next < _angles.length ? _angles[next] : 'All angles captured!';
        });
      }
    } catch (e) {
      setState(() => _instruction = 'Error: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _save() async {
    if (_collected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.registerFace(widget.student.id, _collected);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face registered successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final captured = _collected.length;
    final total = _angles.length;
    final done = captured >= total;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Register Face — ${widget.student.name}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            child: _camReady && _cam != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: CameraPreview(_cam!),
                  )
                : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          // Bottom controls
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              children: [
                // Progress dots
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 0; i < total; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < captured ? AppColors.present : Colors.white24,
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                Text('$captured / $total angles captured',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                // Instruction
                Text(_instruction,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                // Capture / Save button
                if (!done)
                  GestureDetector(
                    onTap: _capturing ? null : _captureAngle,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _capturing ? Colors.white24 : Colors.transparent,
                      ),
                      child: _capturing
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                    ),
                  )
                else ...[
                  Text('Great! All $total angles captured.',
                      style: const TextStyle(color: AppColors.present, fontSize: 14)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Face Data'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() { _collected.clear(); _instruction = _angles[0]; }),
                    child: const Text('Re-capture', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
