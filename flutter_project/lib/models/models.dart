class Teacher {
  final int? id;
  final String name;
  final String username;
  final String passwordHash;
  final bool isAdmin;
  final bool isActive;

  const Teacher({
    this.id, required this.name, required this.username,
    required this.passwordHash, this.isAdmin = false, this.isActive = true,
  });

  Teacher copyWith({int? id, String? name, String? username,
      String? passwordHash, bool? isAdmin, bool? isActive}) =>
    Teacher(id: id ?? this.id, name: name ?? this.name,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      isAdmin: isAdmin ?? this.isAdmin, isActive: isActive ?? this.isActive);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name, 'username': username,
    'password_hash': passwordHash, 'is_admin': isAdmin ? 1 : 0,
    'is_active': isActive ? 1 : 0,
  };

  factory Teacher.fromMap(Map<String, dynamic> m) => Teacher(
    id: m['id'], name: m['name'], username: m['username'],
    passwordHash: m['password_hash'],
    isAdmin: m['is_admin'] == 1, isActive: m['is_active'] == 1);
}

class SchoolClass {
  final int? id;
  final String name;
  final int teacherId;
  final String? section;
  final String? year;

  const SchoolClass({this.id, required this.name, required this.teacherId,
    this.section, this.year});

  SchoolClass copyWith({int? id, String? name, int? teacherId,
      String? section, String? year}) =>
    SchoolClass(id: id ?? this.id, name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      section: section ?? this.section, year: year ?? this.year);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name, 'teacher_id': teacherId,
    if (section != null) 'section': section, if (year != null) 'year': year,
  };

  factory SchoolClass.fromMap(Map<String, dynamic> m) => SchoolClass(
    id: m['id'], name: m['name'], teacherId: m['teacher_id'],
    section: m['section'], year: m['year']);
}

class Student {
  final int? id;
  final String name;
  final String admissionNo;
  final int classId;

  const Student({this.id, required this.name,
    required this.admissionNo, required this.classId});

  Student copyWith({int? id, String? name, String? admissionNo, int? classId}) =>
    Student(id: id ?? this.id, name: name ?? this.name,
      admissionNo: admissionNo ?? this.admissionNo,
      classId: classId ?? this.classId);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name,
    'admission_no': admissionNo, 'class_id': classId,
  };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
    id: m['id'], name: m['name'],
    admissionNo: m['admission_no'], classId: m['class_id']);
}

class AttendanceRecord {
  final int? id;
  final int classId;
  final int studentId;
  final int teacherId;
  final String date;
  final String status; // present | absent | late

  const AttendanceRecord({this.id, required this.classId,
    required this.studentId, required this.teacherId,
    required this.date, required this.status});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'class_id': classId, 'student_id': studentId,
    'teacher_id': teacherId, 'date': date, 'status': status,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
    id: m['id'], classId: m['class_id'], studentId: m['student_id'],
    teacherId: m['teacher_id'], date: m['date'], status: m['status']);
}

class AttendanceEntry {
  final Student student;
  String status;
  AttendanceEntry({required this.student, this.status = 'present'});
}
