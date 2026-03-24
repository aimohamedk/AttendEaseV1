import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  String hashPassword(String password) =>
    sha256.convert(utf8.encode(password)).toString();

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'attendease.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        teacher_id INTEGER NOT NULL,
        section TEXT,
        year TEXT,
        FOREIGN KEY (teacher_id) REFERENCES teachers(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        admission_no TEXT NOT NULL,
        class_id INTEGER NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        UNIQUE(student_id, date),
        FOREIGN KEY (class_id) REFERENCES classes(id),
        FOREIGN KEY (student_id) REFERENCES students(id)
      )
    ''');
    // Seed admin account
    await db.insert('teachers', {
      'name': 'Administrator',
      'username': 'admin',
      'password_hash': hashPassword('admin123'),
      'is_admin': 1,
      'is_active': 1,
    });
    // Seed demo teacher
    await db.insert('teachers', {
      'name': 'Demo Teacher',
      'username': 'teacher',
      'password_hash': hashPassword('teacher123'),
      'is_admin': 0,
      'is_active': 1,
    });
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<Teacher?> login(String username, String password) async {
    final d = await db;
    final rows = await d.query('teachers',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, hashPassword(password)]);
    return rows.isEmpty ? null : Teacher.fromMap(rows.first);
  }

  Future<bool> changePassword(int teacherId, String oldPass, String newPass) async {
    final d = await db;
    final rows = await d.query('teachers',
      where: 'id = ? AND password_hash = ?',
      whereArgs: [teacherId, hashPassword(oldPass)]);
    if (rows.isEmpty) return false;
    await d.update('teachers', {'password_hash': hashPassword(newPass)},
      where: 'id = ?', whereArgs: [teacherId]);
    return true;
  }

  // ── TEACHERS (ADMIN) ──────────────────────────────────────────────────────
  Future<List<Teacher>> getAllTeachers() async {
    final d = await db;
    final rows = await d.query('teachers', orderBy: 'name');
    return rows.map(Teacher.fromMap).toList();
  }

  Future<int> createTeacher(Teacher t) async {
    final d = await db;
    return d.insert('teachers', t.toMap());
  }

  Future<void> updateTeacher(Teacher t) async {
    final d = await db;
    await d.update('teachers', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> resetPassword(int teacherId, String newPass) async {
    final d = await db;
    await d.update('teachers', {'password_hash': hashPassword(newPass)},
      where: 'id = ?', whereArgs: [teacherId]);
  }

  Future<void> toggleTeacherActive(int teacherId, bool active) async {
    final d = await db;
    await d.update('teachers', {'is_active': active ? 1 : 0},
      where: 'id = ?', whereArgs: [teacherId]);
  }

  // ── CLASSES ───────────────────────────────────────────────────────────────
  Future<List<SchoolClass>> getClassesForTeacher(int teacherId) async {
    final d = await db;
    final rows = await d.query('classes',
      where: 'teacher_id = ?', whereArgs: [teacherId], orderBy: 'name');
    return rows.map(SchoolClass.fromMap).toList();
  }

  Future<List<SchoolClass>> getAllClasses() async {
    final d = await db;
    final rows = await d.query('classes', orderBy: 'name');
    return rows.map(SchoolClass.fromMap).toList();
  }

  Future<int> createClass(SchoolClass c) async {
    final d = await db;
    return d.insert('classes', c.toMap());
  }

  Future<void> updateClass(SchoolClass c) async {
    final d = await db;
    await d.update('classes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteClass(int classId) async {
    final d = await db;
    // Cascade delete students and attendance
    final students = await d.query('students',
      where: 'class_id = ?', whereArgs: [classId]);
    for (final s in students) {
      await d.delete('attendance',
        where: 'student_id = ?', whereArgs: [s['id']]);
    }
    await d.delete('students', where: 'class_id = ?', whereArgs: [classId]);
    await d.delete('classes', where: 'id = ?', whereArgs: [classId]);
  }

  // ── STUDENTS ──────────────────────────────────────────────────────────────
  Future<List<Student>> getStudentsForClass(int classId) async {
    final d = await db;
    final rows = await d.query('students',
      where: 'class_id = ?', whereArgs: [classId], orderBy: 'name');
    return rows.map(Student.fromMap).toList();
  }

  Future<int> createStudent(Student s) async {
    final d = await db;
    return d.insert('students', s.toMap());
  }

  Future<void> updateStudent(Student s) async {
    final d = await db;
    await d.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> deleteStudent(int studentId) async {
    final d = await db;
    await d.delete('attendance',
      where: 'student_id = ?', whereArgs: [studentId]);
    await d.delete('students', where: 'id = ?', whereArgs: [studentId]);
  }

  // ── ATTENDANCE ────────────────────────────────────────────────────────────
  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    final d = await db;
    final batch = d.batch();
    for (final r in records) {
      batch.insert('attendance', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<int, String>> getAttendanceForClassDate(
      int classId, String date) async {
    final d = await db;
    final rows = await d.query('attendance',
      where: 'class_id = ? AND date = ?', whereArgs: [classId, date]);
    return {for (final r in rows) r['student_id'] as int: r['status'] as String};
  }

  Future<List<AttendanceRecord>> getAttendanceForRange(
      int classId, String from, String to) async {
    final d = await db;
    final rows = await d.query('attendance',
      where: 'class_id = ? AND date >= ? AND date <= ?',
      whereArgs: [classId, from, to], orderBy: 'date');
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<List<AttendanceRecord>> getStudentAttendanceForRange(
      int studentId, String from, String to) async {
    final d = await db;
    final rows = await d.query('attendance',
      where: 'student_id = ? AND date >= ? AND date <= ?',
      whereArgs: [studentId, from, to], orderBy: 'date');
    return rows.map(AttendanceRecord.fromMap).toList();
  }
}
