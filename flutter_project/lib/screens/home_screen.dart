import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/session.dart';
import '../widgets/app_widgets.dart';
import 'teacher/classes_screen.dart';
import 'attendance/attendance_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'admin/admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = Session.currentTeacher!;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            BrandedHeroCard(
              subtitle: 'Welcome, ${teacher.name}'
                '${teacher.isAdmin ? " · Admin" : ""}'),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.fact_check_rounded, color: AppTheme.accent,
              title: 'Take Attendance',
              subtitle: 'Mark class attendance for today',
              onTap: () => _push(context, const AttendanceScreen())),
            _ActionCard(
              icon: Icons.school_rounded, color: AppTheme.primary,
              title: 'Manage Classes',
              subtitle: 'Add, edit and manage your classes',
              onTap: () => _push(context, const ClassesScreen())),
            _ActionCard(
              icon: Icons.bar_chart_rounded, color: AppTheme.success,
              title: 'Reports',
              subtitle: 'Daily, weekly, term & custom reports',
              onTap: () => _push(context, const ReportsScreen())),
            if (teacher.isAdmin)
              _ActionCard(
                icon: Icons.admin_panel_settings_rounded, color: AppTheme.warning,
                title: 'Admin Panel',
                subtitle: 'Manage teacher accounts',
                onTap: () => _push(context, const AdminScreen())),
            _ActionCard(
              icon: Icons.settings_rounded, color: AppTheme.textSecondary,
              title: 'Settings',
              subtitle: 'Account, password & app info',
              onTap: () => _push(context, const SettingsScreen())),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.color,
    required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
            ])),
            const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondary, size: 22),
          ]),
        ),
      ),
    ),
  );
}
