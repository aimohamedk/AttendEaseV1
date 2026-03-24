import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _db = DatabaseService();
  List<Teacher> _teachers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final t = await _db.getAllTeachers();
    if (mounted) setState(() { _teachers = t; _loading = false; });
  }

  Future<void> _showTeacherDialog([Teacher? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    final userCtrl = TextEditingController(text: existing?.username);
    final passCtrl = TextEditingController();
    bool isAdmin = existing?.isAdmin ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        title: Text(existing == null ? 'Create Teacher' : 'Edit Teacher',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full Name *')),
          const SizedBox(height: 12),
          TextField(controller: userCtrl,
            decoration: const InputDecoration(labelText: 'Username *')),
          const SizedBox(height: 12),
          TextField(controller: passCtrl, obscureText: true,
            decoration: InputDecoration(
              labelText: existing == null
                ? 'Password *' : 'New Password (leave blank to keep)')),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Admin Access'),
            subtitle: const Text('Can manage other teachers'),
            value: isAdmin,
            onChanged: (v) => setSt(() => isAdmin = v),
            contentPadding: EdgeInsets.zero),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(existing == null ? 'Create' : 'Save')),
        ],
      )),
    );

    if (result != true) return;
    if (nameCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty) return;
    if (existing == null && passCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password is required for new teacher')));
      }
      return;
    }

    if (existing == null) {
      await _db.createTeacher(Teacher(
        name: nameCtrl.text.trim(),
        username: userCtrl.text.trim(),
        passwordHash: _db.hashPassword(passCtrl.text),
        isAdmin: isAdmin));
    } else {
      final updated = existing.copyWith(
        name: nameCtrl.text.trim(),
        username: userCtrl.text.trim(),
        isAdmin: isAdmin,
        passwordHash: passCtrl.text.isNotEmpty
          ? _db.hashPassword(passCtrl.text)
          : existing.passwordHash);
      await _db.updateTeacher(updated);
    }
    _load();
  }

  Future<void> _resetPassword(Teacher t) async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset Password — ${t.name}',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password *')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset')),
        ],
      ),
    );
    if (result != true || ctrl.text.isEmpty) return;
    await _db.resetPassword(t.id!, ctrl.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Password reset for ${t.name}'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating));
  }

  Future<void> _toggleActive(Teacher t) async {
    await _db.toggleTeacherActive(t.id!, !t.isActive);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Panel',
      style: TextStyle(fontWeight: FontWeight.w800))),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showTeacherDialog(),
      icon: const Icon(Icons.person_add_rounded),
      label: const Text('Add Teacher', style: TextStyle(fontWeight: FontWeight.w700))),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : _teachers.isEmpty
        ? const EmptyState(icon: Icons.people_outline_rounded,
            title: 'No teachers yet', subtitle: 'Add the first teacher account')
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _teachers.length,
            itemBuilder: (_, i) {
              final t = _teachers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: t.isAdmin
                          ? AppTheme.warning.withOpacity(.15)
                          : AppTheme.primary.withOpacity(.1),
                        child: Icon(
                          t.isAdmin ? Icons.admin_panel_settings_rounded
                            : Icons.person_rounded,
                          color: t.isAdmin ? AppTheme.warning : AppTheme.primary,
                          size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(t.name, style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                          if (t.isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(.15),
                                borderRadius: BorderRadius.circular(20)),
                              child: const Text('ADMIN', style: TextStyle(
                                color: AppTheme.warning, fontSize: 10,
                                fontWeight: FontWeight.w800))),
                          ],
                        ]),
                        Text('@${t.username}', style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.isActive
                              ? AppTheme.success.withOpacity(.1)
                              : AppTheme.danger.withOpacity(.1),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(t.isActive ? 'Active' : 'Deactivated',
                            style: TextStyle(
                              color: t.isActive ? AppTheme.success : AppTheme.danger,
                              fontSize: 11, fontWeight: FontWeight.w700))),
                      ])),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _showTeacherDialog(t);
                          if (v == 'reset') _resetPassword(t);
                          if (v == 'toggle') _toggleActive(t);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit',
                            child: ListTile(leading: Icon(Icons.edit_rounded),
                              title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                          const PopupMenuItem(value: 'reset',
                            child: ListTile(leading: Icon(Icons.lock_reset_rounded),
                              title: Text('Reset Password'),
                              contentPadding: EdgeInsets.zero)),
                          PopupMenuItem(value: 'toggle',
                            child: ListTile(
                              leading: Icon(t.isActive
                                ? Icons.person_off_rounded
                                : Icons.person_rounded),
                              title: Text(t.isActive ? 'Deactivate' : 'Activate'),
                              contentPadding: EdgeInsets.zero)),
                        ],
                      ),
                    ]),
                  ),
                ),
              );
            }),
  );
}
