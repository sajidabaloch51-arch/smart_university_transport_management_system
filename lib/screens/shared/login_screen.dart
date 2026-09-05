import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/driver_provider.dart';
import '../student/student_dashboard.dart';
import '../driver/driver_dashboard.dart';
import '../admin/admin_dashboard.dart';

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

  Future<void> _handleLogin() async {
    final email = _emailController.text.toLowerCase();
    
    if (email.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Determine target role based on email or provided role
    String targetRole = widget.role ?? 'student';
    if (email.contains('driver')) targetRole = 'driver';
    if (email.contains('admin')) targetRole = 'admin';

    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('user_email', email);
      await prefs.setString('user_role', targetRole);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('user_email');
      await prefs.remove('user_role');
    }

    if (targetRole == 'driver') {
      context.read<DriverProvider>().init('driver_123'); // Load data in bg
      context.go('/driver-dashboard');
    } else if (targetRole == 'admin') {
      context.go('/admin-dashboard');
    } else {
      context.go('/student-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleTitle = widget.role != null 
        ? widget.role!.toUpperCase() 
        : 'STUDENT';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.bus_alert_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 32),
              Text(
                '$roleTitle Login',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const Text(
                AppStrings.loginSubtitle,
                style: TextStyle(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email Address',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        activeColor: AppColors.primary,
                      ),
                      const Text('Remember Me', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot Password?', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'LOGIN',
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Not a $roleTitle? "),
                  TextButton(
                    onPressed: () => context.go('/role-selection'),
                    child: const Text('Switch Role', style: TextStyle(fontWeight: FontWeight.bold)),
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
