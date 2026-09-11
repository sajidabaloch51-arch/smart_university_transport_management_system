import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../core/validators/app_validators.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';

class LoginScreen extends StatefulWidget {
  final String? role;
  const LoginScreen({super.key, this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  void _loadSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = 'saved_emails_${widget.role ?? 'student'}';
    setState(() {
      _savedEmails = prefs.getStringList(roleKey) ?? [];
      _rememberMe = _savedEmails.isNotEmpty;
    });
  }

  void _showEmailSuggestions() {
    if (_savedEmails.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Select ${widget.role?.toUpperCase() ?? 'STUDENT'} Email", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ..._savedEmails.map((email) => ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: Text(email),
              onTap: () {
                setState(() {
                  _emailController.text = email;
                });
                Navigator.pop(context);
              },
            )).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveEmailToList(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = 'saved_emails_${widget.role ?? 'student'}';
    List<String> emails = prefs.getStringList(roleKey) ?? [];
    if (!emails.contains(email)) {
      emails.add(email);
      await prefs.setStringList(roleKey, emails);
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final email = _emailController.text.trim().toLowerCase();
      
      // Simulate Login Delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        
        // Use a mock UID for demonstration if real auth isn't connected yet
        final uid = email.split('@')[0] + "_id";

        // Save email to history
        _saveEmailToList(email);

        // Handle Session Persistence
        if (_rememberMe) {
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('remembered_email', email);
          await prefs.setString('uid', uid);
        } else {
          await prefs.setBool('is_logged_in', false);
          await prefs.remove('remembered_email');
          await prefs.remove('uid');
        }

        // Determine Role
        String targetRole = widget.role ?? 'student';
        if (email.contains('admin')) targetRole = 'admin';
        else if (email.contains('driver')) targetRole = 'driver';
        
        await prefs.setString('user_role', targetRole);

        // Update AuthProvider
        if (targetRole == 'student') {
          final studentProvider = context.read<StudentProvider>();
          final student = await studentProvider.getStudent(uid);
          
          if (student != null) {
            if (student.verificationStatus == 'pending') {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account is pending verification by the Admin based on your Roll No.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            } else if (student.verificationStatus == 'rejected') {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your registration request was rejected by the Admin.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }
        }

        context.read<AuthProvider>().setAuthenticated(true, role: targetRole, uid: uid);

        setState(() => _isLoading = false);

        // Navigation
        if (targetRole == 'driver') {
          context.read<DriverProvider>().init('driver_123');
          context.go('/driver-dashboard');
        } else if (targetRole == 'admin') {
          context.go('/admin-dashboard');
        } else {
          context.go('/student-dashboard');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleTitle = widget.role != null 
        ? widget.role!.toUpperCase() 
        : 'STUDENT';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/role-selection');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/role-selection');
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.directions_bus_rounded, size: 80, color: AppColors.primary),
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
                      validator: AppValidators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      onTap: _showEmailSuggestions,
                      autofillHints: const [AutofillHints.email, AutofillHints.username],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) => AppValidators.validateRequired(v, "Password"),
                      maxLength: 20,
                      autofillHints: const [AutofillHints.password],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                          activeColor: AppColors.primary,
                        ),
                        const Text('Remember Me', style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'LOGIN',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            if (widget.role == 'driver') {
                              context.push('/driver-registration');
                            } else if (widget.role == 'admin') {
                              context.push('/admin-registration');
                            } else {
                              context.push('/student-registration');
                            }
                          },
                          child: const Text(
                            "Sign Up", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
