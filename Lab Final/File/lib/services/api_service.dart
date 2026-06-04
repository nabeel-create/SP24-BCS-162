import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  Future<dynamic> _get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode >= 400) throw ApiException(res.body, statusCode: res.statusCode);
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) throw ApiException(res.body, statusCode: res.statusCode);
    if (res.statusCode == 204) return null;
    return jsonDecode(res.body);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) throw ApiException(res.body, statusCode: res.statusCode);
    if (res.statusCode == 204) return null;
    return jsonDecode(res.body);
  }

  Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}$path'));
    if (res.statusCode >= 400) throw ApiException(res.body, statusCode: res.statusCode);
  }

  // ── Departments ──────────────────────────────────────────────────────────
  Future<List<Department>> getDepartments() async {
    final data = await _get('/departments') as List;
    return data.map((d) => Department.fromJson(d)).toList();
  }

  Future<Department> createDepartment({required String name, String? code}) async {
    final data = await _post('/departments', {'name': name, if (code != null) 'code': code});
    return Department.fromJson(data);
  }

  Future<void> deleteDepartment(int id) => _delete('/departments/$id');

  // ── Sections ─────────────────────────────────────────────────────────────
  Future<List<Section>> getSections({int? departmentId}) async {
    final data = await _get('/sections', params: departmentId != null ? {'departmentId': '$departmentId'} : null) as List;
    return data.map((d) => Section.fromJson(d)).toList();
  }

  Future<Section> createSection({required String name, required int departmentId}) async {
    final data = await _post('/sections', {'name': name, 'departmentId': departmentId});
    return Section.fromJson(data);
  }

  Future<void> deleteSection(int id) => _delete('/sections/$id');

  // ── Teachers ─────────────────────────────────────────────────────────────
  Future<List<Teacher>> getTeachers() async {
    final data = await _get('/teachers') as List;
    return data.map((d) => Teacher.fromJson(d)).toList();
  }

  Future<Teacher> createTeacher({required String name, String? email, String? phone, int? departmentId}) async {
    final data = await _post('/teachers', {
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (departmentId != null) 'departmentId': departmentId,
    });
    return Teacher.fromJson(data);
  }

  Future<void> deleteTeacher(int id) => _delete('/teachers/$id');

  // ── Subjects ─────────────────────────────────────────────────────────────
  Future<List<Subject>> getSubjects() async {
    final data = await _get('/subjects') as List;
    return data.map((d) => Subject.fromJson(d)).toList();
  }

  Future<Subject> createSubject({required String name, String? code, int? teacherId}) async {
    final data = await _post('/subjects', {
      'name': name,
      if (code != null) 'code': code,
      if (teacherId != null) 'teacherId': teacherId,
    });
    return Subject.fromJson(data);
  }

  Future<void> deleteSubject(int id) => _delete('/subjects/$id');

  // ── Students ─────────────────────────────────────────────────────────────
  Future<List<Student>> getStudents({String? search, int? departmentId, int? sectionId}) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (departmentId != null) params['departmentId'] = '$departmentId';
    if (sectionId != null) params['sectionId'] = '$sectionId';
    final data = await _get('/students', params: params.isNotEmpty ? params : null) as List;
    return data.map((d) => Student.fromJson(d)).toList();
  }

  Future<Student> getStudent(int id) async {
    final data = await _get('/students/$id');
    return Student.fromJson(data);
  }

  Future<Student> createStudent({
    required String name,
    required String rollNo,
    String? email,
    required int sectionId,
    int? departmentId,
    int? semester,
  }) async {
    final data = await _post('/students', {
      'name': name,
      'rollNo': rollNo,
      if (email != null) 'email': email,
      'sectionId': sectionId,
      if (departmentId != null) 'departmentId': departmentId,
      if (semester != null) 'semester': semester,
    });
    return Student.fromJson(data);
  }

  Future<void> deleteStudent(int id) => _delete('/students/$id');

  Future<void> registerFace(int studentId, List<List<double>> descriptors) async {
    await _patch('/students/$studentId/face', {'descriptors': descriptors});
  }

  Future<List<StudentWithFace>> getStudentsWithFace({int? sectionId}) async {
    final params = <String, String>{};
    if (sectionId != null) params['sectionId'] = '$sectionId';
    final data = await _get('/students/with-faces', params: params.isNotEmpty ? params : null) as List;
    return data.map((d) => StudentWithFace.fromJson(d)).toList();
  }

  // ── Attendance ────────────────────────────────────────────────────────────
  Future<List<AttendanceRecord>> getAttendance({String? date, int? sectionId, int? subjectId, int? studentId}) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (sectionId != null) params['sectionId'] = '$sectionId';
    if (subjectId != null) params['subjectId'] = '$subjectId';
    if (studentId != null) params['studentId'] = '$studentId';
    final data = await _get('/attendance', params: params.isNotEmpty ? params : null) as List;
    return data.map((d) => AttendanceRecord.fromJson(d)).toList();
  }

  Future<double> getStudentAttendancePercentage(int studentId) async {
    final data = await _get('/attendance/student/$studentId/percentage');
    return (data['percentage'] ?? 0).toDouble();
  }

  Future<void> markBulkAttendance({
    required String date,
    required int sectionId,
    required int subjectId,
    required List<Map<String, dynamic>> records,
  }) async {
    final recs = records.map((r) => {
      'studentId': r['studentId'],
      'subjectId': subjectId,
      'date': date,
      'status': r['status'],
    }).toList();
    await _post('/attendance/bulk', {'records': recs});
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<DashboardSummary> getDashboardSummary() async {
    final data = await _get('/dashboard/summary');
    return DashboardSummary.fromJson(data);
  }

  Future<List<TrendPoint>> getAttendanceTrend({int days = 7}) async {
    final data = await _get('/dashboard/attendance-trend', params: {'days': '$days'}) as List;
    return data.map((d) => TrendPoint.fromJson(d)).toList();
  }

  Future<Map<String, int>> getTodayAttendance() async {
    final data = await _get('/dashboard/today-attendance');
    return {
      'present': data['present'] ?? 0,
      'absent': data['absent'] ?? 0,
      'late': data['late'] ?? 0,
    };
  }

  Future<List<DeptStat>> getDepartmentStats() async {
    final data = await _get('/dashboard/department-stats') as List;
    return data.map((d) => DeptStat.fromJson(d)).toList();
  }

  Future<List<ActivityItem>> getRecentActivity() async {
    final data = await _get('/dashboard/recent-activity') as List;
    return data.map((d) => ActivityItem.fromJson(d)).toList();
  }

  // ── Reports / Defaulters ──────────────────────────────────────────────────
  Future<List<DefaulterStudent>> getDefaulters({required double threshold, int? departmentId}) async {
    final params = <String, String>{'threshold': '$threshold'};
    if (departmentId != null) params['departmentId'] = '$departmentId';
    final data = await _get('/attendance/defaulters', params: params) as List;
    return data.map((d) => DefaulterStudent.fromJson(d)).toList();
  }
}
