import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/session.dart';
import '../login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = Session.currentTeacher!;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings',
        style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(.1),
                child: Text(teacher.name.substring(0, 1),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                    color: AppTheme.primary))),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(teacher.name, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
                Text('@${teacher.username}', style: const TextStyle(
                  color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: teacher.isAdmin
                      ? AppTheme.warning.withOpacity(.15)
                      : AppTheme.primary.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(teacher.isAdmin ? 'Administrator' : 'Teacher',
                    style: TextStyle(
                      color: teacher.isAdmin ? AppTheme.warning : AppTheme.primary,
                      fontSize: 11, fontWeight: FontWeight.w700))),
              ])),
            ]),
          )),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Account'),
          _SettingTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your login password',
            onTap: () => _changePasswordDialog(context)),
          const SizedBox(height: 20),
          _SectionLabel(label: 'About'),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _AboutRow(label: 'App', value: 'AttendEase v2.0'),
              _AboutRow(label: 'School', value: AppTheme.schoolName),
              _AboutRow(label: 'City', value: AppTheme.schoolCity),
              _AboutRow(label: 'Phone', value: AppTheme.schoolPhone),
              const Divider(height: 24),
              const Text('Developer', style: TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.textSecondary,
                fontSize: 12)),
              const SizedBox(height: 4),
              _AboutRow(label: 'Name', value: AppTheme.devName),
              _AboutRow(label: 'Phone', value: AppTheme.devPhone),
            ]),
          )),
          const SizedBox(height: 20),
          Card(
            color: AppTheme.danger.withOpacity(.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.danger.withOpacity(.2))),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _logout(context),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Icon(Icons.logout_rounded, color: AppTheme.danger),
                  const SizedBox(width: 14),
                  Text('Sign Out', style: TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.w700,
                    fontSize: 16)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text('Offline-first  •  SQLite  •  PDF sharing',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Future<void> _changePasswordDialog(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password',
          style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldCtrl, obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password')),
          const SizedBox(height: 12),
          TextField(controller: newCtrl, obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password')),
          const SizedBox(height: 12),
          TextField(controller: confCtrl, obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm New Password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Save')),
        ],
      ),
    );
    if (result != true) return;
    if (newCtrl.text != confCtrl.text) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'), backgroundColor: AppTheme.danger));
      return;
    }
    final ok = await DatabaseService().changePassword(
      Session.teacherId, oldCtrl.text, newCtrl.text);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Password changed successfully!'
        : 'Current password is incorrect'),
      backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      behavior: SnackBarBehavior.floating));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Session.logout();
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label.toUpperCase(), style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800,
      color: AppTheme.textSecondary, letterSpacing: 1.2)));
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.title,
    required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(.1),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primary, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15)),
          Text(subtitle, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
      ]),
    ),
  ));
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(
        color: AppTheme.textSecondary, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13))),
    ]));
}
