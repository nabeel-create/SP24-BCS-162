// ─── Models matching the Express API response shapes ──────────────────────────

class Department {
  final int id;
  final String name;
  final String? code;
  Department({required this.id, required this.name, this.code});
  factory Department.fromJson(Map<String, dynamic> j) =>
      Department(id: j['id'], name: j['name'], code: j['code']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
}

class Section {
  final int id;
  final String name;
  final int departmentId;
  final String? departmentName;
  Section({required this.id, required this.name, required this.departmentId, this.departmentName});
  factory Section.fromJson(Map<String, dynamic> j) => Section(
        id: j['id'],
        name: j['name'],
        departmentId: j['departmentId'] ?? j['department_id'] ?? 0,
        departmentName: j['departmentName'],
      );
}

class Teacher {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final int? departmentId;
  final String? departmentName;
  Teacher({required this.id, required this.name, this.email, this.phone, this.departmentId, this.departmentName});
  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        phone: j['phone'],
        departmentId: j['departmentId'] ?? j['department_id'],
        departmentName: j['departmentName'],
      );
}

class Subject {
  final int id;
  final String name;
  final String? code;
  final int? teacherId;
  final String? teacherName;
  Subject({required this.id, required this.name, this.code, this.teacherId, this.teacherName});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'],
        name: j['name'],
        code: j['code'],
        teacherId: j['teacherId'] ?? j['teacher_id'],
        teacherName: j['teacherName'],
      );
}

class Student {
  final int id;
  final String name;
  final String rollNo;
  final String? email;
  final String? phone;
  final int departmentId;
  final String? departmentName;
  final int sectionId;
  final String? sectionName;
  final int? semester;
  final String? profileImage;
  final List<List<double>>? faceDescriptors;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    this.email,
    this.phone,
    required this.departmentId,
    this.departmentName,
    required this.sectionId,
    this.sectionName,
    this.semester,
    this.profileImage,
    this.faceDescriptors,
  });

  bool get hasFace => faceDescriptors != null && faceDescriptors!.isNotEmpty;

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        rollNo: j['rollNo'] ?? j['roll_no'] ?? '',
        email: j['email'],
        phone: j['phone'],
        departmentId: j['departmentId'] ?? j['department_id'] ?? 0,
        departmentName: j['departmentName'],
        sectionId: j['sectionId'] ?? j['section_id'] ?? 0,
        sectionName: j['sectionName'],
        semester: j['semester'],
        profileImage: j['profileImage'] ?? j['profile_image'],
        faceDescriptors: j['faceDescriptors'] != null
            ? (j['faceDescriptors'] as List)
                .map((d) => (d as List).map((v) => (v as num).toDouble()).toList())
                .toList()
            : null,
      );
}

class StudentWithFace {
  final int id;
  final String name;
  final String rollNo;
  final int sectionId;
  final int? semester;
  final List<List<double>> faceDescriptors;

  StudentWithFace({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.sectionId,
    this.semester,
    required this.faceDescriptors,
  });

  factory StudentWithFace.fromJson(Map<String, dynamic> j) => StudentWithFace(
        id: j['id'],
        name: j['name'],
        rollNo: j['rollNo'] ?? j['roll_no'] ?? '',
        sectionId: j['sectionId'] ?? j['section_id'] ?? 0,
        semester: j['semester'],
        faceDescriptors: (j['faceDescriptors'] as List)
            .map((d) => (d as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
      );
}

class AttendanceRecord {
  final int id;
  final int studentId;
  final int? subjectId;
  final String date;
  final String? time;
  final String status; // 'present' | 'absent' | 'late'
  final String? studentName;
  final String? rollNo;
  final String? subjectName;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    this.subjectId,
    required this.date,
    this.time,
    required this.status,
    this.studentName,
    this.rollNo,
    this.subjectName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'],
        studentId: j['studentId'] ?? j['student_id'],
        subjectId: j['subjectId'] ?? j['subject_id'],
        date: j['date'],
        time: j['time'],
        status: j['status'],
        studentName: j['studentName'],
        rollNo: j['rollNo'],
        subjectName: j['subjectName'],
      );
}

class DashboardSummary {
  final int totalStudents;
  final int totalTeachers;
  final int totalDepartments;
  final double attendanceRate;

  DashboardSummary({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalDepartments,
    required this.attendanceRate,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        totalStudents: j['totalStudents'] ?? 0,
        totalTeachers: j['totalTeachers'] ?? 0,
        totalDepartments: j['totalDepartments'] ?? 0,
        attendanceRate: (j['attendanceRateToday'] ?? 0).toDouble(),
      );
}

class TrendPoint {
  final String date;
  final int present;
  final int absent;
  final int late;
  TrendPoint({required this.date, required this.present, required this.absent, required this.late});
  factory TrendPoint.fromJson(Map<String, dynamic> j) =>
      TrendPoint(date: j['date'], present: j['present'] ?? 0, absent: j['absent'] ?? 0, late: j['late'] ?? 0);
}

class DeptStat {
  final String department;
  final double attendanceRate;
  DeptStat({required this.department, required this.attendanceRate});
  factory DeptStat.fromJson(Map<String, dynamic> j) =>
      DeptStat(department: j['departmentName'] ?? '', attendanceRate: (j['attendanceRate'] ?? 0).toDouble());
}

class ActivityItem {
  final int id;
  final String studentName;
  final String rollNo;
  final String status;
  final String time;
  ActivityItem({required this.id, required this.studentName, required this.rollNo, required this.status, required this.time});
  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
        id: j['id'],
        studentName: j['studentName'] ?? '',
        rollNo: j['rollNo'] ?? '',
        status: j['status'] ?? 'absent',
        time: j['time'] ?? j['date'] ?? '',
      );
}

class DefaulterStudent {
  final int id;
  final String name;
  final String rollNo;
  final String? departmentName;
  final double percentage;
  DefaulterStudent({required this.id, required this.name, required this.rollNo, this.departmentName, required this.percentage});
  factory DefaulterStudent.fromJson(Map<String, dynamic> j) => DefaulterStudent(
        id: j['id'],
        name: j['name'],
        rollNo: j['rollNo'] ?? '',
        departmentName: j['departmentName'],
        percentage: (j['percentage'] ?? 0).toDouble(),
      );
}
