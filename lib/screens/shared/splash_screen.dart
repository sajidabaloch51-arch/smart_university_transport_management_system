import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../constants/strings.dart';

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

  void _navigateToNext() async {
    // Run initializations with a max timeout to prevent hanging on slow connections
    try {
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        Firebase.initializeApp().timeout(const Duration(seconds: 2)),
      ]).timeout(const Duration(seconds: 3));
      
      if (!mounted) return;

      final SharedPreferences? prefs = results[0] as SharedPreferences?;
      final bool rememberMe = prefs?.getBool('remember_me') ?? false;
      
      // Only check Firebase auth if Firebase initialized successfully
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {}

      if (rememberMe && user != null) {
        final String? role = prefs?.getString('user_role');
        if (role == 'admin') {
          context.go('/admin-dashboard');
        } else if (role == 'driver') {
          context.go('/driver-dashboard');
        } else {
          context.go('/student-dashboard');
        }
      } else {
        // If rememberMe is false, sign out to ensure re-authentication is required
        if (user != null) {
          await FirebaseAuth.instance.signOut();
        }
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint("Initialization took too long or failed: $e. Proceeding to onboarding.");
      if (mounted) context.go('/onboarding');
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
