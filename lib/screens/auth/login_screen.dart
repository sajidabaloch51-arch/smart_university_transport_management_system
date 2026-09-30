import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/student_provider.dart';
import '../../services/student_access_guard.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

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
    
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      String role = '';
      
      if (email.contains('admin')) {
        role = 'admin';
      } else if (email.contains('driver')) {
        role = 'driver';
      } else {
        role = 'student';
      }

      final uid = "${email.split('@')[0]}_id";

      if (role == 'student') {
        final access = await StudentAccessGuard.evaluate(
          studentProvider: context.read<StudentProvider>(),
          uid: uid,
        );
        if (!access.allowed) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(access.message ?? 'Access denied'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_role', role);
        await prefs.setString('email', email);
        await prefs.setString('uid', uid);
      }

      if (mounted) {
        context.read<AuthProvider>().setAuthenticated(true, 
          role: role, 
          uid: uid,
        );
      }

      setState(() => _isLoading = false);
      context.go(role == 'admin' ? '/admin-dashboard' : (role == 'driver' ? '/driver-dashboard' : '/student-dashboard'));
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
                    onTap: () => context.go('/role-selection'),
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
