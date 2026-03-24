import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/session.dart';
import '../../widgets/app_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _db = DatabaseService();
  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;
  String _reportType = 'daily';
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  bool _loading = true;
  bool _generating = false;

  final _reportTypes = const [
    ('daily', 'Daily', Icons.today_rounded),
    ('weekly', 'Weekly', Icons.calendar_view_week_rounded),
    ('monthly', 'Monthly', Icons.calendar_month_rounded),
    ('term1', 'Term 1', Icons.school_rounded),
    ('term2', 'Term 2', Icons.school_rounded),
    ('term3', 'Term 3', Icons.school_rounded),
    ('custom', 'Custom Range', Icons.date_range_rounded),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final classes = await _db.getClassesForTeacher(Session.teacherId);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      if (classes.isNotEmpty) _selectedClass = classes.first;
      _loading = false;
    });
  }

  (DateTime, DateTime) _dateRange() {
    final now = DateTime.now();
    return switch (_reportType) {
      'daily' => (now, now),
      'weekly' => (now.subtract(Duration(days: now.weekday - 1)),
          now.subtract(Duration(days: now.weekday - 1)).add(const Duration(days: 6))),
      'monthly' => (DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0)),
      'term1' => (DateTime(now.year, 1, 1), DateTime(now.year, 4, 30)),
      'term2' => (DateTime(now.year, 5, 1), DateTime(now.year, 8, 31)),
      'term3' => (DateTime(now.year, 9, 1), DateTime(now.year, 12, 31)),
      _ => (_from, _to),
    };
  }

  Future<void> _generate() async {
    if (_selectedClass == null) return;
    if (_reportType == 'custom' && _from.isAfter(_to)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Start date must be before end date')));
      return;
    }
    setState(() => _generating = true);
    try {
      final (from, to) = _dateRange();
      final fromStr = DateFormat('yyyy-MM-dd').format(from);
      final toStr = DateFormat('yyyy-MM-dd').format(to);
      final records = await _db.getAttendanceForRange(
        _selectedClass!.id!, fromStr, toStr);
      final students = await _db.getStudentsForClass(_selectedClass!.id!);
      if (!mounted) return;
      await PdfService().generateClassReport(
        schoolClass: _selectedClass!,
        teacher: Session.currentTeacher!,
        students: students,
        records: records,
        from: from, to: to,
        reportType: _reportType,
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    loading: _generating,
    child: Scaffold(
      appBar: AppBar(title: const Text('Reports',
        style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _classes.isEmpty
          ? const EmptyState(icon: Icons.bar_chart_outlined,
              title: 'No classes yet',
              subtitle: 'Create a class to generate reports')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Report Settings',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<SchoolClass>(
                      value: _selectedClass,
                      items: _classes.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _selectedClass = v),
                      decoration: const InputDecoration(labelText: 'Select Class',
                        prefixIcon: Icon(Icons.class_rounded)),
                    ),
                  ]),
                )),
                const SizedBox(height: 14),
                const SectionHeader(title: 'Report Type'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: _reportTypes.map((t) {
                    final selected = _reportType == t.$1;
                    return FilterChip(
                      selected: selected,
                      label: Text(t.$2),
                      avatar: Icon(t.$3, size: 16),
                      onSelected: (_) => setState(() => _reportType = t.$1),
                      selectedColor: AppTheme.primary.withOpacity(.15),
                      checkmarkColor: AppTheme.primary,
                    );
                  }).toList()),
                if (_reportType == 'custom') ...[
                  const SizedBox(height: 14),
                  Card(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _DateRow(label: 'From', date: _from,
                        onTap: () async {
                          final d = await showDatePicker(context: context,
                            initialDate: _from,
                            firstDate: DateTime(2020), lastDate: DateTime.now());
                          if (d != null) setState(() => _from = d);
                        }),
                      const Divider(height: 20),
                      _DateRow(label: 'To', date: _to,
                        onTap: () async {
                          final d = await showDatePicker(context: context,
                            initialDate: _to,
                            firstDate: DateTime(2020), lastDate: DateTime.now());
                          if (d != null) setState(() => _to = d);
                        }),
                    ]),
                  )),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Generate & Share PDF',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
              ],
            ),
    ),
  );
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateRow({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(children: [
      Text(label, style: const TextStyle(
        fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(width: 12),
      Expanded(child: Text(DateFormat('d MMMM yyyy').format(date),
        style: const TextStyle(fontWeight: FontWeight.w700))),
      const Icon(Icons.edit_calendar_rounded,
        color: AppTheme.textSecondary, size: 18),
    ]),
  );
}
