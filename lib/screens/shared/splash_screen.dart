import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/notice_provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/student_access_guard.dart';
import '../../services/live_firestore.dart';

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

  Future<void> _softCheckStudentAccess(
    SharedPreferences prefs,
    String uid,
  ) async {
    try {
      final access = await StudentAccessGuard.evaluate(
        studentProvider: context.read<StudentProvider>(),
        uid: uid,
      ).timeout(const Duration(seconds: 6));
      if (!access.allowed) {
        await _clearSession(prefs);
        if (!mounted) return;
        context.go('/login', extra: 'student');
      }
    } catch (_) {
      // Offline / slow — leave dashboard open.
    }
  }

  Future<void> _navigateToNext() async {
    // Tiny delay so splash paints once; avoid long network waits on cold start.
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? role = prefs.getString('user_role');
    final String? uid = prefs.getString('uid');

    if (isLoggedIn && role != null && uid != null) {
      // Restore session immediately — never block splash on network.
      if (!mounted) return;
      context.read<AuthProvider>().setAuthenticated(true, role: role, uid: uid);
      context.read<AuthProvider>().cacheProfile(role: role);

      if (!mounted) return;
      switch (role) {
        case 'admin':
          LiveFirestore.warmAdminLists();
          context.go('/admin-dashboard');
          break;
        case 'driver':
          context.read<DriverProvider>().init(uid);
          context.go('/driver-dashboard');
          break;
        default:
          if (!mounted) return;
          context.read<RouteProvider>().streamRoutes();
          context.read<NoticeProvider>().streamNotices();
          context.go('/student-dashboard');
          // Soft access check in background; kick out only if denied.
          // ignore: discarded_futures
          _softCheckStudentAccess(prefs, uid);
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
