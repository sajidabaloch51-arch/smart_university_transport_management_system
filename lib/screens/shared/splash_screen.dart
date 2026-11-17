import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
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
import '../../services/auth_role_resolver.dart';
import '../../services/firestore_service.dart';
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
    await context.read<AuthProvider>().logout();
  }

  /// Wait until Firebase Auth restores its persisted session (or times out).
  Future<User?> _waitForFirebaseAuth() async {
    final auth = FirebaseAuth.instance;
    final existing = auth.currentUser;
    if (existing != null) return existing;

    try {
      return await auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      return auth.currentUser;
    } catch (_) {
      return auth.currentUser;
    }
  }

  /// Prefer Firestore role over stale SharedPreferences role.
  Future<String> _resolveRole(User firebaseUser, String? prefsRole) async {
    String? byUidRole;
    String? byEmailRole;
    try {
      final service = FirestoreService();
      final byUid = await service.getUser(firebaseUser.uid);
      byUidRole = byUid?.role;
      final email = firebaseUser.email;
      if (email != null && email.isNotEmpty) {
        final byEmail = await service.findUserByEmail(email);
        byEmailRole = byEmail?.role;
        if (AuthRoleResolver.needsRoleMirror(
          authUid: firebaseUser.uid,
          profileUid: byEmail?.uid,
          role: byEmailRole,
        )) {
          await service.ensureAuthUidRoleMirror(
            authUid: firebaseUser.uid,
            role: byEmailRole!.trim().toLowerCase(),
            email: email,
            name: byEmail?.name ?? '',
            phone: byEmail?.phone ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('Splash role resolve failed: $e');
    }
    return AuthRoleResolver.resolve(
      firestoreRoleByUid: byUidRole,
      firestoreRoleByEmail: byEmailRole,
      prefsRole: prefsRole,
    );
  }

  Future<void> _softCheckStudentAccess(
    SharedPreferences prefs,
    String authUid,
  ) async {
    try {
      final access = await StudentAccessGuard.evaluate(
        studentProvider: context.read<StudentProvider>(),
        uid: authUid,
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
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final bool prefsLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? prefsRole = prefs.getString('user_role');

    final firebaseUser = await _waitForFirebaseAuth();
    if (!mounted) return;

    if (firebaseUser == null) {
      if (prefsLoggedIn) {
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('uid');
      }
      if (!mounted) return;
      context.go('/onboarding');
      return;
    }

    final uid = firebaseUser.uid;
    final resolvedRole = await _resolveRole(firebaseUser, prefsRole);
    if (!mounted) return;

    await prefs.setBool('is_logged_in', true);
    await prefs.setString('uid', uid);
    await prefs.setString('user_role', resolvedRole);

    if (!mounted) return;
    context.read<AuthProvider>().setAuthenticated(
          true,
          role: resolvedRole,
          uid: uid,
          email: firebaseUser.email,
        );
    context.read<AuthProvider>().cacheProfile(
          role: resolvedRole,
          email: firebaseUser.email,
        );

    if (!mounted) return;
    switch (resolvedRole) {
      case 'admin':
        LiveFirestore.warmAdminLists();
        context.go('/admin-dashboard');
        break;
      case 'driver':
        context.read<DriverProvider>().init(uid);
        context.go('/driver-dashboard');
        break;
      default:
        context.read<RouteProvider>().streamRoutes();
        context.read<NoticeProvider>().streamNotices();
        context.go('/student-dashboard');
        // ignore: discarded_futures
        _softCheckStudentAccess(prefs, uid);
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
