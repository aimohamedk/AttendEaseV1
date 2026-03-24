import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary    = Color(0xFF1A3A6B);
  static const Color primaryLight = Color(0xFF2557A7);
  static const Color accent     = Color(0xFF3A86FF);
  static const Color success    = Color(0xFF198754);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color danger     = Color(0xFFDC3545);
  static const Color surface    = Color(0xFFF4F7FF);
  static const Color cardBg     = Colors.white;
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const String schoolName = 'AL AHGAAF INTERNATIONAL SCHOOL';
  static const String schoolCity = 'Mukallah, Yemen';
  static const String schoolPhone = '+967 773 561 050';
  static const String appName = 'AttendEase';
  static const String devName = 'Abdullahi Issack Mohamed';
  static const String devPhone = '+967 7832 440 93';

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary, brightness: Brightness.light),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: textPrimary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8EEF8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1DCF0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1DCF0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryLight, width: 1.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary, foregroundColor: Colors.white,
    ),
  );
}
