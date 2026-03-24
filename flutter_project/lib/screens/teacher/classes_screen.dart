import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/session.dart';
import '../../widgets/app_widgets.dart';
import 'students_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _db = DatabaseService();
  List<SchoolClass> _classes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final classes = Session.isAdmin
      ? await _db.getAllClasses()
      : await _db.getClassesForTeacher(Session.teacherId);
    if (mounted) setState(() { _classes = classes; _loading = false; });
  }

  Future<void> _showClassDialog([SchoolClass? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final sectionCtrl = TextEditingController(text: existing?.section);
    final yearCtrl = TextEditingController(text: existing?.year);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Class' : 'Edit Class',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Class Name *',
              hintText: 'e.g. Grade 7A')),
          const SizedBox(height: 12),
          TextField(controller: sectionCtrl,
            decoration: const InputDecoration(labelText: 'Section (optional)')),
          const SizedBox(height: 12),
          TextField(controller: yearCtrl,
            decoration: const InputDecoration(labelText: 'Year (optional)',
              hintText: 'e.g. 2024/2025')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: Text(existing == null ? 'Add' : 'Save')),
        ],
      ),
    );
    if (result != true || nameCtrl.text.trim().isEmpty) return;
    if (existing == null) {
      await _db.createClass(SchoolClass(
        name: nameCtrl.text.trim(), teacherId: Session.teacherId,
        section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
        year: yearCtrl.text.trim().isEmpty ? null : yearCtrl.text.trim()));
    } else {
      await _db.updateClass(existing.copyWith(
        name: nameCtrl.text.trim(),
        section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
        year: yearCtrl.text.trim().isEmpty ? null : yearCtrl.text.trim()));
    }
    _load();
  }

  Future<void> _delete(SchoolClass c) async {
    if (!await confirmDelete(context, c.name)) return;
    await _db.deleteClass(c.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Classes',
      style: TextStyle(fontWeight: FontWeight.w800))),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showClassDialog(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.w700))),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _classes.isEmpty
        ? const EmptyState(icon: Icons.school_outlined,
            title: 'No classes yet',
            subtitle: 'Tap "Add Class" to create your first class')
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _classes.length,
            itemBuilder: (_, i) {
              final c = _classes[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => StudentsScreen(schoolClass: c)))
                      .then((_) => _load()),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(.1),
                            borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.class_rounded,
                            color: AppTheme.primary)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                          if (c.section != null || c.year != null)
                            Text([if (c.section != null) c.section!, if (c.year != null) c.year!].join(' • '),
                              style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () => _showClassDialog(c),
                          color: AppTheme.textSecondary),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          onPressed: () => _delete(c),
                          color: AppTheme.danger),
                        const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                      ]),
                    ),
                  ),
                ),
              );
            }),
  );
}
