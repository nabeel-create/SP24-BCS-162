import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/face_api_service.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_view.dart';

class CameraAttendanceScreen extends StatefulWidget {
  const CameraAttendanceScreen({super.key});
  @override
  State<CameraAttendanceScreen> createState() => _CameraAttendanceScreenState();
}

class _CameraAttendanceScreenState extends State<CameraAttendanceScreen> {
  CameraController? _cam;
  bool _camReady = false;
  bool _scanning = false;
  bool _submitting = false;
  bool _submitted = false;
  List<RecognizedFace> _recognized = [];
  List<Section> _sections = [];
  List<Subject> _subjects = [];
  List<StudentWithFace> _enrolledFaces = [];
  int? _sectionId;
  int? _subjectId;
  bool _initing = true;
  String? _faceApiStatus;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    try {
      final res = await Future.wait([
        ApiService.instance.getSections(),
        ApiService.instance.getSubjects(),
        FaceApiService.instance.isHealthy(),
      ]);
      _sections = res[0] as List<Section>;
      _subjects = res[1] as List<Subject>;
      final healthy = res[2] as bool;
      _faceApiStatus = healthy ? null : '⚠ Face recognition server offline';
      await _initCamera();
    } catch (e) {
      if (mounted) setState(() => _initing = false);
    }
    if (mounted) setState(() => _initing = false);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cam = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _cam!.initialize();
    if (mounted) setState(() => _camReady = true);
  }

  @override
  void dispose() { _cam?.dispose(); super.dispose(); }

  Future<void> _loadEnrolled() async {
    if (_sectionId == null) { _enrolledFaces = []; return; }
    final faces = await ApiService.instance.getStudentsWithFace(sectionId: _sectionId);
    if (mounted) setState(() => _enrolledFaces = faces);
  }

  Future<void> _scan() async {
    if (!_camReady || _scanning || _cam == null) return;
    if (_enrolledFaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No enrolled faces for this section')));
      return;
    }
    setState(() => _scanning = true);
    try {
      final photo = await _cam!.takePicture();
      final bytes = await photo.readAsBytes();
      final b64 = base64Encode(bytes);
      final results = await FaceApiService.instance.recognize(imageBase64: b64, enrolledFaces: _enrolledFaces);
      if (results.isNotEmpty && mounted) {
        setState(() {
          final existing = Set<int>.from(_recognized.map((r) => r.studentId));
          final newOnes = results.where((r) => !existing.contains(r.studentId)).toList();
          _recognized = [..._recognized, ...newOnes];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan error: $e')));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _submit() async {
    if (_sectionId == null || _subjectId == null || _recognized.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.instance.markBulkAttendance(
        date: DateTime.now().toIso8601String().split('T')[0],
        sectionId: _sectionId!,
        subjectId: _subjectId!,
        records: _recognized.map((r) => {'studentId': r.studentId, 'status': 'present'}).toList(),
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera Attendance'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _initing
          ? const LoadingView()
          : _submitted
              ? _buildSuccess()
              : Column(
                  children: [
                    if (_faceApiStatus != null)
                      Container(
                        color: AppColors.absentBg,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(children: [
                          const Icon(Icons.warning_amber, color: AppColors.absent, size: 16),
                          const SizedBox(width: 6),
                          Text(_faceApiStatus!, style: const TextStyle(color: AppColors.absent, fontSize: 12)),
                        ]),
                      ),
                    // Camera preview
                    Expanded(
                      child: _camReady && _cam != null
                          ? CameraPreview(_cam!)
                          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    // Bottom controls
                    Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      child: Column(
                        children: [
                          // Section + Subject
                          Row(children: [
                            Expanded(
                              child: DropdownButton<int?>(
                                value: _sectionId,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                hint: const Text('Section', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                underline: Container(height: 1, color: Colors.white24),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Section', style: TextStyle(color: Colors.white70))),
                                  ..._sections.map((s) => DropdownMenuItem(value: s.id,
                                      child: Text(s.name, style: const TextStyle(color: Colors.white)))),
                                ],
                                onChanged: (v) { setState(() => _sectionId = v); _loadEnrolled(); },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButton<int?>(
                                value: _subjectId,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                hint: const Text('Subject', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                underline: Container(height: 1, color: Colors.white24),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Subject', style: TextStyle(color: Colors.white70))),
                                  ..._subjects.map((s) => DropdownMenuItem(value: s.id,
                                      child: Text(s.name, style: const TextStyle(color: Colors.white)))),
                                ],
                                onChanged: (v) => setState(() => _subjectId = v),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          // Recognized faces
                          if (_recognized.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_recognized.length} recognized:',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6, runSpacing: 4,
                                    children: _recognized.map((r) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.presentBg, borderRadius: BorderRadius.circular(20)),
                                      child: Text(r.studentName, style: const TextStyle(fontSize: 11, color: AppColors.present, fontWeight: FontWeight.w600)),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            // Scan button
                            GestureDetector(
                              onTap: _scanning ? null : _scan,
                              child: Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  color: _scanning ? Colors.white24 : Colors.transparent,
                                ),
                                child: _scanning
                                    ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.face_retouching_natural, color: Colors.white, size: 26),
                              ),
                            ),
                            // Submit button
                            if (_recognized.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check),
                                label: Text('Mark ${_recognized.length}'),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSuccess() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle, size: 72, color: AppColors.present),
      const SizedBox(height: 16),
      Text('${_recognized.length} students marked present!',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
    ]),
  );
}
