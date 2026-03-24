import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/session.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() { _userCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter username and password'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final teacher = await DatabaseService()
          .login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (teacher == null) {
        setState(() { _error = 'Invalid credentials or account deactivated';
          _loading = false; });
      } else {
        Session.login(teacher);
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF2557A7)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(padding: const EdgeInsets.all(28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Center(child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD1DCF0))),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/branding/school_logo.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                        Image.asset('assets/branding/school_logo.png',
                          fit: BoxFit.contain))))),
                const SizedBox(height: 18),
                const Text(AppTheme.schoolName, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: AppTheme.primary, height: 1.3)),
                const SizedBox(height: 6),
                const Text('Teacher Attendance Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 28),
                TextField(controller: _userCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded))),
                const SizedBox(height: 14),
                TextField(controller: _passCtrl, obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure)))),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1F0),
                      borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(
                      color: AppTheme.danger, fontSize: 13))),
                ],
                const SizedBox(height: 22),
                SizedBox(height: 52, child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text('Sign In', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)))),
                const SizedBox(height: 16),
                const Text('Default: admin / admin123',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
              ])),
          ),
        ),
      ))),
    ),
  );
}
