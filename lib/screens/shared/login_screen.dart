import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../constants/strings.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../core/validators/app_validators.dart';
import '../../services/student_access_guard.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/password_hasher.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/email_validator.dart';

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
            )),
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = AppEmailValidator.normalize(_emailController.text);
    final password = _passwordController.text;
    final portalRole = widget.role ?? 'student';

    try {
      final prefs = await SharedPreferences.getInstance();
      _saveEmailToList(email);

      String uid;
      String accountRole = '';

      // Prefer Firebase Auth. Fall back to Firestore profile + optional passwordHash.
      try {
        final authUser = await AuthService().signIn(email, password);
        uid = authUser.uid;
        final firestoreUser = await FirestoreService().getUser(uid) ??
            await FirestoreService().findUserByEmail(email);
        accountRole = firestoreUser?.role ?? '';
      } on AuthServiceException catch (authErr) {
        // Firestore fallback for demo admin/driver/student when Auth is off.
        final profile = await FirestoreService().getUserAuthProfile(email);
        if (profile == null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authErr.message),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final hash = profile.passwordHash;
        if (hash != null && hash.isNotEmpty) {
          if (!PasswordHasher.verify(password, hash)) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect email or password.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else if (!AuthService.isConfigurationError(authErr)) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authErr.message),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        uid = profile.uid;
        accountRole = profile.role;
      }

      // Role comes from Firestore (or the portal), never from the email domain.
      String targetRole =
          accountRole.isNotEmpty ? accountRole : portalRole;

      if (portalRole == 'admin' && targetRole != 'admin') {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No admin account for this email. Admins are provisioned by the university.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (accountRole.isNotEmpty && accountRole != portalRole) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This account is registered as $accountRole. Please use the $accountRole portal.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      targetRole = portalRole;

      if (_rememberMe) {
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('remembered_email', email);
        await prefs.setString('uid', uid);
      } else {
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('remembered_email');
        await prefs.remove('uid');
      }
      await prefs.setString('user_role', targetRole);

      if (!mounted) return;

      if (targetRole == 'student') {
        final access = await StudentAccessGuard.evaluate(
          studentProvider: context.read<StudentProvider>(),
          uid: uid,
        );

        if (!access.allowed) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(access.message ?? 'Access denied'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      context.read<AuthProvider>().setAuthenticated(
            true,
            role: targetRole,
            uid: uid,
          );

      setState(() => _isLoading = false);

      if (!mounted) return;
      if (targetRole == 'driver') {
        context.read<DriverProvider>().init(uid);
        context.go('/driver-dashboard');
      } else if (targetRole == 'admin') {
        context.go('/admin-dashboard');
      } else {
        context.go('/student-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String roleTitle = widget.role != null 
        ? widget.role!.toUpperCase() 
        : 'STUDENT';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
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
                      hintText: AppEmailValidator.hint,
                      helperText: AppEmailValidator.hint,
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                              activeColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text(
                              'Remember Me',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
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
