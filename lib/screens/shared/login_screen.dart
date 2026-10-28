import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/strings.dart';
import '../../core/validators/app_validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/notice_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/auth_service.dart';
import '../../services/autofill_policy.dart';
import '../../services/firestore_service.dart';
import '../../services/live_firestore.dart';
import '../../services/password_hasher.dart';
import '../../services/remember_me_store.dart';
import '../../services/student_access_guard.dart';
import '../../theme/app_colors.dart';
import '../../utils/email_validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

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
  bool _autofillFinished = false;
  List<String> _savedEmails = [];

  String get _portalRole => widget.role ?? 'student';

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    AutofillPolicy.enableNormalAutofill();
    _loadSavedEmails();
  }

  @override
  void dispose() {
    if (!_autofillFinished) {
      TextInput.finishAutofillContext(shouldSave: false);
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _finishAutofill({required bool shouldSave}) async {
    if (_autofillFinished) return;
    _autofillFinished = true;
    if (shouldSave) {
      await AutofillPolicy.commitSave();
    } else {
      await AutofillPolicy.cancelSave();
    }
  }

  void _loadSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = 'saved_emails_$_portalRole';
    final remembered = await RememberMeStore.readEmail(_portalRole);
    if (!mounted) return;
    setState(() {
      _savedEmails = prefs.getStringList(roleKey) ?? [];
      if (remembered != null && remembered.isNotEmpty) {
        _emailController.text = remembered;
        _rememberMe = true;
        if (!_savedEmails.contains(remembered)) {
          _savedEmails = [..._savedEmails, remembered];
        }
      } else {
        _rememberMe = _savedEmails.isNotEmpty;
      }
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
    final roleKey = 'saved_emails_$_portalRole';
    final emails = prefs.getStringList(roleKey) ?? [];
    if (!emails.contains(email)) {
      emails.add(email);
      await prefs.setStringList(roleKey, emails);
    }
  }

  Future<void> _handleLogin() async {
    // Do not cancel autofill on validation — user may fix and succeed.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = AppEmailValidator.normalize(_emailController.text);
    final password = _passwordController.text;
    final portalRole = _portalRole;

    try {
      final prefs = await SharedPreferences.getInstance();
      _saveEmailToList(email);

      String uid;
      String accountRole = '';

      // Prefer Firebase Auth. Fall back to Firestore profile + optional passwordHash.
      try {
        final authUser = await AuthService().signIn(email, password);
        // Duties/alerts use Firestore users/{docId}. Prefer that doc id over
        // Auth uid when they differ (seed docs are driver_id / admin_id).
        final firestoreUser = await FirestoreService().getUser(authUser.uid) ??
            await FirestoreService().findUserByEmail(email);
        uid = firestoreUser?.uid ?? authUser.uid;
        accountRole = firestoreUser?.role ?? '';
        debugPrint(
          'Login Auth uid=${authUser.uid} profileUid=$uid role=$accountRole',
        );
      } on AuthServiceException catch (authErr) {
        // Firestore fallback for demo admin/driver/student when Auth is off.
        final profile = await FirestoreService().getUserAuthProfile(email);
        if (profile == null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          await _finishAutofill(shouldSave: false);
          if (!mounted) return;
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
            await _finishAutofill(shouldSave: false);
            if (!mounted) return;
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
          await _finishAutofill(shouldSave: false);
          if (!mounted) return;
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
        await _finishAutofill(shouldSave: false);
        if (!mounted) return;
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
        await _finishAutofill(shouldSave: false);
        if (!mounted) return;
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

      // Remember Me: email only (never the password). Email → secure storage.
      if (_rememberMe) {
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('uid', uid);
        await RememberMeStore.writeEmail(portalRole, email);
      } else {
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('uid');
        await RememberMeStore.clearEmail(portalRole);
      }
      await prefs.setString('user_role', targetRole);

      if (!mounted) return;

      if (targetRole == 'student') {
        debugPrint('Student login access check for uid=$uid email=$email');
        final access = await StudentAccessGuard.evaluate(
          studentProvider: context.read<StudentProvider>(),
          uid: uid,
        );

        if (!access.allowed) {
          // Auth may already be signed in — clear so a retry starts clean.
          try {
            await AuthService().signOut();
          } catch (_) {}
          if (!mounted) return;
          setState(() => _isLoading = false);
          await _finishAutofill(shouldSave: false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(access.message ?? 'Access denied'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        // Prefer Firestore profile uid from the fresh student doc.
        if (access.student != null && access.student!.uid.isNotEmpty) {
          uid = access.student!.uid;
        }
      }

      // Offer Save password while fields are still mounted, then navigate.
      await _finishAutofill(shouldSave: true);

      if (!mounted) return;
      context.read<AuthProvider>().setAuthenticated(
            true,
            role: targetRole,
            uid: uid,
            email: email,
          );
      context.read<AuthProvider>().cacheProfile(
            email: email,
            role: targetRole,
          );

      if (!mounted) return;
      if (targetRole == 'admin') {
        LiveFirestore.warmAdminLists();
        context.go('/admin-dashboard');
      } else if (targetRole == 'driver') {
        context.read<DriverProvider>().init(uid);
        context.go('/driver-dashboard');
      } else {
        context.read<RouteProvider>().streamRoutes();
        context.read<NoticeProvider>().streamNotices();
        context.go('/student-dashboard');
      }
    } catch (e) {
      await _finishAutofill(shouldSave: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always clear the login spinner (success, validation exit, or error).
      if (mounted && _isLoading) setState(() => _isLoading = false);
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
              onDisposeAction: AutofillContextAction.commit,
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
                      textInputAction: TextInputAction.next,
                      // Do not steal focus with a custom sheet — Google autofill needs the tap.
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                    ),
                    if (_savedEmails.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _showEmailSuggestions,
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Saved in app'),
                        ),
                      ),
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) _handleLogin();
                      },
                      validator: (v) =>
                          AppValidators.validateRequired(v, 'Password'),
                      maxLength: 20,
                      enableSuggestions: false,
                      autocorrect: false,
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
                    if (widget.role == 'driver') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Driver accounts are created by the Transport Office. '
                        'Contact the Admin if you can\'t log in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (widget.role == 'admin') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Admin accounts are provisioned by the university. '
                        'Self-registration is not available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () =>
                                context.push('/student-registration'),
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
