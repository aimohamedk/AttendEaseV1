import '../models/models.dart';

class Session {
  static Teacher? currentTeacher;
  static bool get isLoggedIn => currentTeacher != null;
  static bool get isAdmin => currentTeacher?.isAdmin ?? false;
  static int get teacherId => currentTeacher!.id!;

  static void login(Teacher t) => currentTeacher = t;
  static void logout() => currentTeacher = null;
}
