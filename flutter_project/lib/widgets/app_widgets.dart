import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── SECTION HEADER ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary))),
      if (action != null) action!,
    ],
  );
}

// ── STATUS BADGE ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'present' => (AppTheme.success, const Color(0xFFEAFBF1), 'Present'),
      'absent'  => (AppTheme.danger, const Color(0xFFFFF1F0), 'Absent'),
      'late'    => (AppTheme.warning, const Color(0xFFFFFBEB), 'Late'),
      _ => (AppTheme.textSecondary, AppTheme.surface, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg,
        borderRadius: BorderRadius.circular(20)),
      child: Text(label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const StatCard({super.key, required this.label, required this.value,
    required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    ),
  );
}

// ── EMPTY STATE ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.icon,
    required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18,
          fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary)),
      ]),
    ),
  );
}

// ── CONFIRM DIALOG ────────────────────────────────────────────────────────────
Future<bool> confirmDelete(BuildContext context, String itemName) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('Are you sure you want to delete "$itemName"?\nThis action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete')),
      ],
    ),
  );
  return result ?? false;
}

// ── LOADING OVERLAY ───────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  const LoadingOverlay({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (loading)
      const ColoredBox(color: Color(0x66000000),
        child: Center(child: CircularProgressIndicator(color: Colors.white))),
  ]);
}

// ── BRANDED HERO CARD ─────────────────────────────────────────────────────────
class BrandedHeroCard extends StatelessWidget {
  final String subtitle;
  const BrandedHeroCard({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [AppTheme.primary, AppTheme.primaryLight],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(.3),
        blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/branding/school_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
              Image.asset('assets/branding/school_logo.jpg', fit: BoxFit.contain))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AL AHGAAF INTERNATIONAL SCHOOL',
            style: TextStyle(color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      )),
    ]),
  );
}
