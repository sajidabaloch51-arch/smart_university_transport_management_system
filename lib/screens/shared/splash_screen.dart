import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/student_access_guard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_role');
    await prefs.remove('uid');
    if (!mounted) return;
    context.read<AuthProvider>().logout();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? role = prefs.getString('user_role');
    final String? uid = prefs.getString('uid');

    if (isLoggedIn && role != null && uid != null) {
      if (role == 'student') {
        final access = await StudentAccessGuard.evaluate(
          studentProvider: context.read<StudentProvider>(),
          uid: uid,
        );
        if (!access.allowed) {
          await _clearSession(prefs);
          if (!mounted) return;
          context.go('/login', extra: 'student');
          return;
        }
      }

      if (!mounted) return;
      context.read<AuthProvider>().setAuthenticated(true, role: role, uid: uid);

      if (!mounted) return;
      switch (role) {
        case 'admin':
          context.go('/admin-dashboard');
          break;
        case 'driver':
          context.go('/driver-dashboard');
          break;
        default:
          context.go('/student-dashboard');
      }
    } else {
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_filled, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              AppStrings.appSubtitle,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
