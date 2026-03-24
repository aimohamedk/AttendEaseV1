import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class StudentsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const StudentsScreen({super.key, required this.schoolClass});
  @override State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _db = DatabaseService();
  List<Student> _students = [];
  List<Student> _filtered = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final s = await _db.getStudentsForClass(widget.schoolClass.id!);
    if (mounted) setState(() {
      _students = s;
      _filter();
      _loading = false;
    });
  }

  void _filter() {
    final q = _query.toLowerCase();
    _filtered = q.isEmpty ? _students : _students.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.admissionNo.toLowerCase().contains(q)).toList();
  }

  Future<void> _showStudentDialog([Student? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final admCtrl = TextEditingController(text: existing?.admissionNo);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Student' : 'Edit Student',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full Name *')),
          const SizedBox(height: 12),
          TextField(controller: admCtrl,
            decoration: const InputDecoration(labelText: 'Admission Number *',
              hintText: 'e.g. AE001')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: Text(existing == null ? 'Add' : 'Save')),
        ],
      ),
    );
    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty || admCtrl.text.trim().isEmpty) return;
    if (existing == null) {
      await _db.createStudent(Student(
        name: nameCtrl.text.trim(), admissionNo: admCtrl.text.trim(),
        classId: widget.schoolClass.id!));
    } else {
      await _db.updateStudent(existing.copyWith(
        name: nameCtrl.text.trim(), admissionNo: admCtrl.text.trim()));
    }
    _load();
  }

  Future<void> _delete(Student s) async {
    if (!await confirmDelete(context, s.name)) return;
    await _db.deleteStudent(s.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.schoolClass.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${_students.length} students',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showStudentDialog(),
      icon: const Icon(Icons.person_add_rounded),
      label: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.w700))),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() { _query = v; _filter(); }),
          decoration: const InputDecoration(
            hintText: 'Search students...',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder()),
        ),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _filtered.isEmpty
          ? EmptyState(
              icon: Icons.people_outline_rounded,
              title: _query.isEmpty ? 'No students yet' : 'No results',
              subtitle: _query.isEmpty
                ? 'Tap "Add Student" to add the first student'
                : 'Try a different search term')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final s = _filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(.1),
                        child: Text(s.name.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary))),
                      title: Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Adm: ${s.admissionNo}',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () => _showStudentDialog(s),
                          color: AppTheme.textSecondary),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          onPressed: () => _delete(s),
                          color: AppTheme.danger),
                      ]),
                    ),
                  ),
                );
              })),
    ]),
  );
}
