import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class RecognizedFace {
  final int studentId;
  final String studentName;
  final double distance;
  RecognizedFace({required this.studentId, required this.studentName, required this.distance});
  factory RecognizedFace.fromJson(Map<String, dynamic> j) => RecognizedFace(
        studentId: j['student_id'],
        studentName: j['student_name'] ?? '',
        distance: (j['distance'] ?? 0).toDouble(),
      );
}

class FaceApiService {
  static final FaceApiService instance = FaceApiService._();
  FaceApiService._();

  Future<List<double>?> extractEmbedding(String imageBase64) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.faceApiUrl}/extract-embedding'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': imageBase64}),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      return (data['embedding'] as List).map((v) => (v as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<RecognizedFace>> recognize({
    required String imageBase64,
    required List<StudentWithFace> enrolledFaces,
  }) async {
    // Only pass ArcFace embeddings (512-dim) to the Python service
    final enrolled = enrolledFaces
        .where((s) => s.faceDescriptors.isNotEmpty && s.faceDescriptors[0].length == 512)
        .map((s) => {
              'student_id': s.id,
              'student_name': s.name,
              'embeddings': s.faceDescriptors,
            })
        .toList();

    if (enrolled.isEmpty) return [];

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.faceApiUrl}/recognize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': imageBase64, 'enrolled_faces': enrolled}),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return (data['recognized'] as List).map((f) => RecognizedFace.fromJson(f)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isHealthy() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.faceApiUrl}/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
