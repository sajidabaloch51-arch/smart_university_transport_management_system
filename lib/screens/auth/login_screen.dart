import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../student/student_dashboard.dart';
import '../driver/driver_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? role;
  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  void _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    
    if (email.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credentials')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate Login Delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      String role = '';
      Widget destination;
      
      // Automatic Role Routing Logic
      if (email.contains('admin')) {
        role = 'admin';
        destination = const AdminDashboard();
      } else if (email.contains('driver')) {
        role = 'driver';
        destination = const DriverDashboard();
      } else {
        role = 'student';
        destination = const StudentDashboard();
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', role);
        await prefs.setString('email', email);
      }

      setState(() => _isLoading = false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Hero(
                tag: 'auth_icon',
                child: Icon(Icons.directions_bus_rounded, size: 80, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 32),
              const Text(
                "University of Gwadar",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Smart Transport System",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              CustomTextField(
                controller: _emailController,
                labelText: "Email", 
                prefixIcon: Icons.email_outlined,
              ),
              
              CustomTextField(
                controller: _passwordController,
                labelText: "Password", 
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                maxLength: 20,
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v!)),
                      const Text("Remember Me", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text("Forgot Password?", style: TextStyle(fontSize: 12))
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              CustomButton(
                text: "LOGIN",
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen())),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
