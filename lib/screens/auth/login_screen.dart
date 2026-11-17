import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy login screen — kept only to avoid broken imports.
/// Real login is [screens/shared/login_screen.dart] (Firebase Auth).
class LoginScreen extends StatelessWidget {
  final String? role;
  const LoginScreen({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go('/login', extra: role ?? 'student');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
