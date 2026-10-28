import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/validators/app_validators.dart';
import '../../models/admin_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/autofill_policy.dart';
import '../../services/firestore_service.dart';
import '../../utils/email_validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() =>
      _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _autofillFinished = false;
  Uint8List? _webImage;

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

  Future<void> _finishAutofill({required bool shouldSave}) async {
    if (_autofillFinished) return;
    _autofillFinished = true;
    if (shouldSave) {
      await AutofillPolicy.commitSave();
    } else {
      await AutofillPolicy.cancelSave();
    }
  }

  @override
  void dispose() {
    if (!_autofillFinished) {
      TextInput.finishAutofillContext(shouldSave: false);
      _autofillFinished = true;
    }
    _nameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = AppEmailValidator.normalize(_emailController.text);

    // Open self-registration blocked: email must be on approvedAdmins allowlist.
    final allowed = await FirestoreService().isApprovedAdminEmail(email);
    if (!allowed) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _finishAutofill(shouldSave: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This email is not on the approved admin list. '
            'Admin accounts are created by the university only.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    String profileImageBase64 = '';
    if (_webImage != null) {
      profileImageBase64 = base64Encode(_webImage!);
    }

    final admin = AdminModel(
      uid: "${email.split('@')[0]}_admin_id",
      name: _nameController.text.trim(),
      email: email,
      phone: _phoneController.text.trim(),
      role: 'admin',
      university: 'University of Gwadar',
      profilePhoto: profileImageBase64,
      employeeId: _employeeIdController.text.trim(),
    );

    try {
      await Provider.of<AdminProvider>(context, listen: false).addAdmin(admin);

      await _finishAutofill(shouldSave: true);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final prefs = await SharedPreferences.getInstance();
      const roleKey = 'saved_emails_admin';
      final emails = prefs.getStringList(roleKey) ?? <String>[];
      if (!emails.contains(admin.email)) {
        emails.add(admin.email);
        await prefs.setStringList(roleKey, emails);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Admin Account Created',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your administrator account has been successfully registered. '
            'Please log in with your official credentials to access the Admin Panel.',
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: ElevatedButton(
                  onPressed: () => context.go('/login', extra: 'admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      await _finishAutofill(shouldSave: false);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Registration"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                                  Icons.admin_panel_settings,
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
                    'Upload Official Photo',
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
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.validateFullName,
                  autofillHints: const [AutofillHints.name],
                ),
                CustomTextField(
                  controller: _employeeIdController,
                  labelText: 'Employee ID',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.validateEmployeeId,
                ),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Official Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.validatePhone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Official Email',
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
                const SizedBox(height: 24),
                CustomButton(
                  text: "CREATE ADMIN ACCOUNT",
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => context.go('/login', extra: 'admin'),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
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
    );
  }
}
