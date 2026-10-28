import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/validators/app_validators.dart';
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../services/auth_service.dart';
import '../../services/autofill_policy.dart';
import '../../services/password_hasher.dart';
import '../../utils/email_validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditStudentScreen extends StatefulWidget {
  final StudentModel? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _regController;
  late TextEditingController _deptController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _routeController;

  bool _isLoading = false;
  bool _sendingReset = false;
  bool _autofillFinished = false;

  Uint8List? _webImage;

  bool get _isNew => widget.student == null;

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
  void initState() {
    super.initState();
    // ignore: discarded_futures
    AutofillPolicy.enableNormalAutofill();
    _nameController = TextEditingController(text: widget.student?.name);
    _rollNoController = TextEditingController(text: widget.student?.rollNo);
    _regController = TextEditingController(text: widget.student?.regNumber);
    _deptController = TextEditingController(text: widget.student?.department);
    _emailController = TextEditingController(text: widget.student?.email);
    _phoneController = TextEditingController(text: widget.student?.phone);
    _routeController = TextEditingController(text: widget.student?.routeAddress);
    _passwordController = TextEditingController();
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
    _rollNoController.dispose();
    _regController.dispose();
    _deptController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordReset() async {
    final emailError = AppValidators.validateEmail(_emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _sendingReset = true);
    try {
      await AuthService().sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. The student can set their own password '
            '(saved to their Google account when they complete the link).',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String profileImageBase64 = widget.student?.profileImage ?? '';
    if (_webImage != null) {
      profileImageBase64 = base64Encode(_webImage!);
    }

    final email = AppEmailValidator.normalize(_emailController.text);
    var uid = widget.student?.uid ?? '';
    String? passwordHash;
    final tempPassword = _isNew ? _passwordController.text : '';

    try {
      if (_isNew) {
        try {
          // Secondary FirebaseApp — Admin Auth session stays intact.
          final authUser = await AuthService()
              .createUserKeepCurrentSession(email, tempPassword);
          uid = authUser.uid;
        } on AuthServiceException catch (e) {
          if (!AuthService.isConfigurationError(e)) rethrow;
          uid = '${email.split('@').first}_id';
          passwordHash = PasswordHasher.hash(tempPassword);
        }
      }

      final student = StudentModel(
        uid: uid,
        email: email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'student',
        regNumber: _regController.text.trim(),
        department: _deptController.text.trim(),
        profileImage: profileImageBase64,
        routeAddress: _routeController.text.trim(),
        rollNo: _rollNoController.text.trim(),
        verificationStatus: widget.student?.verificationStatus ?? 'approved',
        passwordHash: passwordHash ?? widget.student?.passwordHash,
        assignedRouteId: widget.student?.assignedRouteId,
        assignedRouteName: widget.student?.assignedRouteName,
        assignedBusId: widget.student?.assignedBusId,
        assignedBusName: widget.student?.assignedBusName,
        assignedBusCode: widget.student?.assignedBusCode,
        assignedDriverId: widget.student?.assignedDriverId,
        assignedDriverName: widget.student?.assignedDriverName,
        assignedDriverPhone: widget.student?.assignedDriverPhone,
        assignedDepartureTime: widget.student?.assignedDepartureTime,
        assignedArrivalTime: widget.student?.assignedArrivalTime,
        termsAccepted: widget.student?.termsAccepted ?? false,
        termsVersion: widget.student?.termsVersion,
      );

      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);
      await studentProvider.addStudent(student);

      // Keep field values mounted until Save password is offered.
      if (_isNew && tempPassword.isNotEmpty) {
        await _finishAutofill(shouldSave: true);
      } else {
        await _finishAutofill(shouldSave: false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isNew
                ? 'Student added successfully'
                : 'Student updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      await _finishAutofill(shouldSave: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (widget.student?.profileImage != null &&
        widget.student!.profileImage.isNotEmpty) {
      if (widget.student!.profileImage.startsWith('http')) {
        imageProvider = NetworkImage(widget.student!.profileImage);
      } else {
        try {
          imageProvider =
              MemoryImage(base64Decode(widget.student!.profileImage));
        } catch (e) {
          debugPrint('Error decoding base64 image: $e');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add Student' : 'Edit Student'),
      ),
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.commit,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child:
                            Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                labelText: 'Student Full Name',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateFullName,
                autofillHints: const [AutofillHints.name],
              ),
              CustomTextField(
                controller: _rollNoController,
                labelText: 'Roll No',
                prefixIcon: Icons.format_list_numbered,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateRollNo,
              ),
              CustomTextField(
                controller: _regController,
                labelText: 'Registration Number (Optional)',
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateRegistrationNumber,
              ),
              CustomTextField(
                controller: _deptController,
                labelText: 'Department',
                prefixIcon: Icons.school_outlined,
                textInputAction: TextInputAction.next,
              ),
              CustomTextField(
                controller: _emailController,
                labelText: 'Student email',
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
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validatePhone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              CustomTextField(
                controller: _routeController,
                labelText: 'Route Address',
                prefixIcon: Icons.map_outlined,
                textInputAction:
                    _isNew ? TextInputAction.next : TextInputAction.done,
                validator: (v) =>
                    AppValidators.validateRequired(v, 'Route Address'),
              ),
              if (_isNew) ...[
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  validator: AppValidators.validatePassword,
                  maxLength: 20,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                OutlinedButton.icon(
                  onPressed: _sendingReset ? null : _sendPasswordReset,
                  icon: _sendingReset
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_outlined),
                  label: Text(
                    _sendingReset
                        ? 'Sending…'
                        : 'Send password reset email to user',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              CustomButton(
                text: _isNew ? 'ADD STUDENT' : 'UPDATE STUDENT',
                isLoading: _isLoading,
                onPressed: _saveForm,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
