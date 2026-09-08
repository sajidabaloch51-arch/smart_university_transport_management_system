import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../student/student_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../driver/driver_dashboard.dart';

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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? role = prefs.getString('role');

    if (isLoggedIn && role != null) {
      Widget destination;
      switch (role) {
        case 'admin':
          destination = const AdminDashboard();
          break;
        case 'driver':
          destination = const DriverDashboard();
          break;
        default:
          destination = const StudentDashboard();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'auth_icon',
              child: Icon(Icons.directions_bus_rounded, size: 100, color: Color(0xFF1565C0)),
            ),
            SizedBox(height: 20),
            Text(
              "SUTMS",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
                letterSpacing: 2,
              ),
            ),
            Text(
              "University of Gwadar",
              style: TextStyle(color: Colors.grey, letterSpacing: 1.5),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
