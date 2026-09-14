import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../models/student_model.dart';
import '../../services/university_db_service.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
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
  bool _isLoading = false;
  
  Uint8List? _webImage;
  XFile? _pickedFile;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        var f = await image.readAsBytes();
        setState(() {
          _webImage = f;
          _pickedFile = image;
        });
      } else {
        setState(() {
          _pickedFile = image;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _regController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select your department")),
        );
        return;
      }
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please accept terms and conditions")),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      String profileImageBase64 = '';
      if (_webImage != null) {
        profileImageBase64 = base64Encode(_webImage!);
      }

      final rollNo = _rollNoController.text.trim();
      final officialRecord = UniversityDBService.lookupRecord(rollNo);
      final status = officialRecord != null ? 'approved' : 'pending';

      final student = StudentModel(
        uid: _emailController.text.trim().split('@')[0] + "_id",
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'student',
        regNumber: _regController.text.trim(),
        fatherName: '',
        gender: '',
        dob: '',
        department: _selectedDepartment!,
        semester: '1',
        profileImage: profileImageBase64,
        routeAddress: '',
        rollNo: rollNo,
        assignedRouteId: null,
        assignedRouteName: null,
        verificationStatus: status,
      );

      try {
        await Provider.of<StudentProvider>(context, listen: false).addStudent(student);
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          final prefs = await SharedPreferences.getInstance();
          const roleKey = 'saved_emails_student';
          List<String> emails = prefs.getStringList(roleKey) ?? [];
          if (!emails.contains(student.email)) {
            emails.add(student.email);
            await prefs.setStringList(roleKey, emails);
          }

          if (status == 'approved') {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                    SizedBox(width: 10),
                    Text("Verified & Registered"),
                  ],
                ),
                content: const Text(
                  "Your Roll No was found in official records. Your account is auto-approved. "
                  "You can now log in to access the portal."
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ElevatedButton(
                      onPressed: () => context.go('/login', extra: 'student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("PROCEED TO LOGIN", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 10),
                    Text("Registration Pending"),
                  ],
                ),
                content: const Text(
                  "Your Roll No was not found in immediate official records. "
                  "Your registration has been submitted for manual Admin verification. "
                  "Please wait for approval before logging in."
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ElevatedButton(
                      onPressed: () => context.go('/login', extra: 'student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("OK, PROCEED TO LOGIN", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration failed: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/student-portal-entry');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Student Registration"),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
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
                                ? const Icon(Icons.person_add_rounded, size: 50, color: Color(0xFF1565C0))
                                : null,
                          ),
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF1565C0),
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Upload Profile Photo",
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 22),
                  
                  CustomTextField(
                    controller: _nameController,
                    labelText: "Full Name", 
                    prefixIcon: Icons.person_outline,
                    validator: AppValidators.validateFullName,
                    autofillHints: const [AutofillHints.name],
                  ),

                  CustomTextField(
                    controller: _rollNoController,
                    labelText: "Roll No", 
                    prefixIcon: Icons.format_list_numbered,
                    validator: AppValidators.validateRollNo,
                  ),
                  
                  CustomTextField(
                    controller: _regController,
                    labelText: "Registration Number (Optional)", 
                    prefixIcon: Icons.badge_outlined,
                    validator: AppValidators.validateRegistrationNumber,
                  ),

                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Department",
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    value: _selectedDepartment,
                    items: _departments.map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedDepartment = v),
                    validator: (v) => v == null ? 'Select your department' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _phoneController,
                    labelText: "Phone Number", 
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.validatePhone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: _emailController,
                    labelText: "Email Address", 
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.validateEmail,
                    autofillHints: const [AutofillHints.email, AutofillHints.newUsername],
                  ),
                  
                  CustomTextField(
                    controller: _passController,
                    labelText: "Password", 
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: AppValidators.validatePassword,
                    maxLength: 20,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  
                  CustomTextField(
                    controller: _confirmPassController,
                    labelText: "Confirm Password", 
                    prefixIcon: Icons.lock_reset_outlined,
                    isPassword: true,
                    validator: (v) => AppValidators.validateConfirmPassword(v, _passController.text),
                    maxLength: 20,
                  ),
                  
                  CheckboxListTile(
                    value: _termsAccepted,
                    onChanged: (v) => setState(() => _termsAccepted = v!),
                    title: const Text("I accept terms and conditions", style: TextStyle(fontSize: 12)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 24),
                  CustomButton(
                    text: "REGISTER",
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => context.go('/login', extra: 'student'),
                        child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
