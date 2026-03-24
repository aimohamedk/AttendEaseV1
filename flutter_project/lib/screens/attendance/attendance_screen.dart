import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/session.dart';
import '../../widgets/app_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _db = DatabaseService();
  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;
  List<AttendanceEntry> _entries = [];
  bool _loadingClasses = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String _query = '';
  DateTime _date = DateTime.now();

  @override
  void initState() { super.initState(); _loadClasses(); }

  Future<void> _loadClasses() async {
    final classes = await _db.getClassesForTeacher(Session.teacherId);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _loadingClasses = false;
      if (classes.isNotEmpty) {
        _selectedClass = classes.first;
        _loadStudents();
      }
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedClass == null) return;
    setState(() { _loadingStudents = true; _entries = []; });
    final students = await _db.getStudentsForClass(_selectedClass!.id!);
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final existing = await _db.getAttendanceForClassDate(
      _selectedClass!.id!, dateStr);
    if (!mounted) return;
    setState(() {
      _entries = students.map((s) => AttendanceEntry(
        student: s, status: existing[s.id] ?? 'present')).toList();
      _loadingStudents = false;
    });
  }

  Future<void> _save() async {
    if (_selectedClass == null || _entries.isEmpty) return;
    setState(() => _saving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final records = _entries.map((e) => AttendanceRecord(
      classId: _selectedClass!.id!, studentId: e.student.id!,
      teacherId: Session.teacherId, date: dateStr, status: e.status)).toList();
    await _db.saveAttendance(records);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Attendance saved successfully!'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _bulkSet(String status) =>
    setState(() { for (final e in _entries) e.status = status; });

  List<AttendanceEntry> get _filtered {
    final q = _query.toLowerCase();
    return q.isEmpty ? _entries : _entries.where((e) =>
      e.student.name.toLowerCase().contains(q) ||
      e.student.admissionNo.toLowerCase().contains(q)).toList();
  }

  int get _present => _entries.where((e) => e.status == 'present').length;
  int get _absent  => _entries.where((e) => e.status == 'absent').length;
  int get _late    => _entries.where((e) => e.status == 'late').length;

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context,
      initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) { setState(() => _date = d); _loadStudents(); }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    loading: _saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Take Attendance',
        style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loadingClasses
        ? const Center(child: CircularProgressIndicator())
        : _classes.isEmpty
          ? const EmptyState(icon: Icons.school_outlined,
              title: 'No classes assigned',
              subtitle: 'Create a class first from Manage Classes')
          : Column(children: [
              // Controls card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // Date picker
                    InkWell(onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded,
                            color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('EEEE, d MMMM yyyy').format(_date),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded,
                            color: AppTheme.textSecondary, size: 18),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Class dropdown
                    DropdownButtonFormField<SchoolClass>(
                      value: _selectedClass,
                      items: _classes.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.name))).toList(),
                      onChanged: (v) {
                        setState(() => _selectedClass = v);
                        _loadStudents();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        prefixIcon: Icon(Icons.class_rounded)),
                    ),
                    if (_entries.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        StatCard(label: 'Total', value: '${_entries.length}',
                          color: AppTheme.primary, bg: const Color(0xFFEEF3FF)),
                        const SizedBox(width: 8),
                        StatCard(label: 'Present', value: '$_present',
                          color: AppTheme.success, bg: const Color(0xFFEAFBF1)),
                        const SizedBox(width: 8),
                        StatCard(label: 'Absent', value: '$_absent',
                          color: AppTheme.danger, bg: const Color(0xFFFFF1F0)),
                        const SizedBox(width: 8),
                        StatCard(label: 'Late', value: '$_late',
                          color: AppTheme.warning, bg: const Color(0xFFFFFBEB)),
                      ]),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search_rounded),
                          isDense: true),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _QuickBtn(label: 'All Present',
                          color: AppTheme.success,
                          onTap: () => _bulkSet('present'))),
                        const SizedBox(width: 8),
                        Expanded(child: _QuickBtn(label: 'All Absent',
                          color: AppTheme.danger,
                          onTap: () => _bulkSet('absent'))),
                        const SizedBox(width: 8),
                        Expanded(child: _QuickBtn(label: 'All Late',
                          color: AppTheme.warning,
                          onTap: () => _bulkSet('late'))),
                      ]),
                    ],
                  ]),
                )),
              ),
              // Student list
              Expanded(child: _loadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                  ? const EmptyState(icon: Icons.people_outline_rounded,
                      title: 'No students in this class',
                      subtitle: 'Add students from Manage Classes')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final entry = _filtered[i];
                        return _StudentTile(
                          entry: entry,
                          onStatusChanged: (s) =>
                            setState(() => entry.status = s));
                      })),
            ]),
      bottomNavigationBar: _entries.isEmpty ? null : SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Attendance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ),
      ),
    ),
  );
}

class _StudentTile extends StatelessWidget {
  final AttendanceEntry entry;
  final ValueChanged<String> onStatusChanged;
  const _StudentTile({required this.entry, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final s = entry.student;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: _bgColor(entry.status),
              child: Text(s.name.substring(0, 1),
                style: TextStyle(fontWeight: FontWeight.w800,
                  color: _fgColor(entry.status)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Adm: ${s.admissionNo}',
                style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            _StatusToggle(status: entry.status, onChanged: onStatusChanged),
          ]),
        ),
      ),
    );
  }

  Color _bgColor(String s) => switch (s) {
    'present' => const Color(0xFFEAFBF1),
    'absent'  => const Color(0xFFFFF1F0),
    'late'    => const Color(0xFFFFFBEB),
    _ => AppTheme.surface,
  };
  Color _fgColor(String s) => switch (s) {
    'present' => AppTheme.success,
    'absent'  => AppTheme.danger,
    'late'    => AppTheme.warning,
    _ => AppTheme.textSecondary,
  };
}

class _StatusToggle extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;
  const _StatusToggle({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      for (final s in ['present', 'absent', 'late'])
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: status == s ? _color(s) : _color(s).withOpacity(.1),
                borderRadius: BorderRadius.circular(20)),
              child: Text(_label(s), style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: status == s ? Colors.white : _color(s))),
            ),
          ),
        ),
    ]);

  Color _color(String s) => switch (s) {
    'present' => AppTheme.success,
    'absent'  => AppTheme.danger,
    'late'    => AppTheme.warning,
    _ => AppTheme.textSecondary,
  };
  String _label(String s) => switch (s) {
    'present' => 'P', 'absent' => 'A', 'late' => 'L', _ => s,
  };
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.3))),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        color: color, fontWeight: FontWeight.w700, fontSize: 12))),
  );
}
