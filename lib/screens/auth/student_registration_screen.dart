import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/student_terms.dart';
import '../../core/validators/app_validators.dart';
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../services/auth_service.dart';
import '../../services/autofill_policy.dart';
import '../../services/password_hasher.dart';
import '../../services/university_db_service.dart';
import '../../utils/email_validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/terms_conditions_sheet.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _regController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String? _selectedDepartment;

  final List<String> _departments = [
    'Computer Science',
    'Business Administration',
    'Education',
    'Economics',
    'Commerce',
    'Chemistry',
    'Zoology',
    'English',
  ];

  bool _termsAccepted = false;
  bool _showTermsError = false;
  bool _isLoading = false;
  bool _autofillFinished = false;
  late final TapGestureRecognizer _termsTapRecognizer;

  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    AutofillPolicy.enableNormalAutofill();
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openTerms();
      };
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    }
  }

  @override
  void dispose() {
    if (!_autofillFinished) {
      TextInput.finishAutofillContext(shouldSave: false);
      _autofillFinished = true;
    }
    _termsTapRecognizer.dispose();
    _nameController.dispose();
    _rollNoController.dispose();
    _regController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final agreed = await showTermsAndConditionsSheet(context, role: 'student');
    if (!mounted) return;
    if (agreed == true) {
      setState(() {
        _termsAccepted = true;
        _showTermsError = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    // Do not cancel autofill on validation — user may fix and succeed.
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your department')),
      );
      return;
    }
    if (!_termsAccepted) {
      setState(() => _showTermsError = true);
      return;
    }

    setState(() => _isLoading = true);

    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    final rollNo = UniversityDBService.normalizeRollNo(_rollNoController.text);
    final regNo = _regController.text.trim();
    final email = AppEmailValidator.normalize(_emailController.text);
    final password = _passController.text;

    try {
      // Duplicate roll number
      final existing = await studentProvider.findByRollNo(rollNo);
      if (existing != null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await _finishAutofill(shouldSave: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Roll No "$rollNo" is already registered. Please log in or contact admin.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Official records lookup (awaited; network ≠ not found)
      UniversityStudentRecord? officialRecord;
      try {
        officialRecord = await UniversityDBService.findOfficialMatch(
          rollNo: rollNo,
          registrationNo: regNo.isEmpty ? null : regNo,
        );
      } on OfficialLookupException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await _finishAutofill(shouldSave: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
        return;
      }

      if (officialRecord != null &&
          officialRecord.enrollmentStatus != 'Active') {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await _finishAutofill(shouldSave: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot register: university enrollment status is "${officialRecord.enrollmentStatus}".',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final status =
          (officialRecord != null &&
                  officialRecord.enrollmentStatus == 'Active')
              ? 'approved'
              : 'pending';

      // Prefer Firebase Auth. If Email/Password is not enabled in Console,
      // fall back to salted hash in Firestore (never plaintext).
      String uid;
      String? passwordHash;
      try {
        final authUser = await AuthService().createUser(email, password);
        uid = authUser.uid;
      } on AuthServiceException catch (e) {
        if (!AuthService.isConfigurationError(e)) rethrow;
        uid = '${email.split('@').first}_id';
        passwordHash = PasswordHasher.hash(password);
        debugPrint(
          'Firebase Auth not configured — using secure local hash fallback.',
        );
      }

      String profileImageBase64 = '';
      if (_webImage != null) {
        profileImageBase64 = base64Encode(_webImage!);
      }

      final student = StudentModel(
        uid: uid,
        name: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        role: 'student',
        regNumber: regNo.isNotEmpty
            ? regNo
            : (officialRecord?.regNumber ?? ''),
        department: _selectedDepartment!,
        profileImage: profileImageBase64,
        rollNo: rollNo,
        verificationStatus: status,
        passwordHash: passwordHash,
        termsAccepted: true,
        termsVersion: kStudentTermsVersion,
      );

      await studentProvider.addStudent(student);

      // Controllers still hold values — commit Save password before navigating.
      await _finishAutofill(shouldSave: true);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final prefs = await SharedPreferences.getInstance();
      const roleKey = 'saved_emails_student';
      final emails = prefs.getStringList(roleKey) ?? <String>[];
      if (!emails.contains(email)) {
        emails.add(email);
        await prefs.setStringList(roleKey, emails);
      }

      if (!mounted) return;
      if (status == 'approved') {
        _showResultDialog(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          title: 'Verified & Registered',
          body:
              'Your Roll No was found in official university records and your account is auto-approved. You can log in now.',
        );
      } else {
        _showResultDialog(
          icon: Icons.hourglass_empty_rounded,
          iconColor: Colors.orange,
          title: 'Awaiting Admin Approval',
          body:
              'Your Roll No was not found in official records. Your registration was saved as pending. An administrator must approve your account before you can log in.',
        );
      }
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _finishAutofill(shouldSave: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _finishAutofill(shouldSave: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResultDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(body),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ElevatedButton(
                onPressed: () => context.go('/login', extra: 'student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/student-portal-entry');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Registration'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/student-portal-entry');
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.commit,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFE3F2FD),
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(
                                      Icons.person_add_rounded,
                                      size: 50,
                                      color: Color(0xFF1565C0),
                                    )
                                  : null,
                            ),
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF1565C0),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Upload Profile Photo',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: AppValidators.validateFullName,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    CustomTextField(
                      controller: _rollNoController,
                      labelText: 'Roll No',
                      prefixIcon: Icons.format_list_numbered,
                      validator: AppValidators.validateRollNo,
                      textInputAction: TextInputAction.next,
                    ),
                    CustomTextField(
                      controller: _regController,
                      labelText: 'Registration Number (Optional)',
                      prefixIcon: Icons.badge_outlined,
                      validator: AppValidators.validateRegistrationNumber,
                      textInputAction: TextInputAction.next,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Department',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      initialValue: _selectedDepartment,
                      items: _departments
                          .map(
                            (dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDepartment = v),
                      validator: (v) =>
                          v == null ? 'Select your department' : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.validatePhone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      hintText: AppEmailValidator.hint,
                      helperText: AppEmailValidator.hint,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validateEmail,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                    ),
                    CustomTextField(
                      controller: _passController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validatePassword,
                      maxLength: 20,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    CustomTextField(
                      controller: _confirmPassController,
                      labelText: 'Confirm Password',
                      prefixIcon: Icons.lock_reset_outlined,
                      isPassword: true,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      validator: (v) => AppValidators.validateConfirmPassword(
                        v,
                        _passController.text,
                      ),
                      maxLength: 20,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Checkbox(
                            value: _termsAccepted,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) {
                              setState(() {
                                _termsAccepted = v ?? false;
                                if (_termsAccepted) _showTermsError = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                  height: 1.35,
                                ),
                                children: [
                                  const TextSpan(text: 'I accept the '),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF1565C0),
                                    ),
                                    recognizer: _termsTapRecognizer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Read terms and conditions',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF1565C0),
                            size: 22,
                          ),
                          onPressed: _openTerms,
                        ),
                      ],
                    ),
                    if (_showTermsError)
                      const Padding(
                        padding: EdgeInsets.only(left: 36, top: 4, bottom: 4),
                        child: Text(
                          'Please accept the Terms & Conditions to continue.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'REGISTER',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Already have an account? '),
                          GestureDetector(
                            onTap: () =>
                                context.go('/login', extra: 'student'),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ),
                        ],
                      ),
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
