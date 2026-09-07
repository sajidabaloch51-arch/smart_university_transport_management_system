import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/student_model.dart';
import '../student/student_dashboard.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
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
    _regController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
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
        department: 'BS IT',
        semester: '1',
        profileImage: profileImageBase64,
        routeAddress: _addressController.text.trim(),
        verificationStatus: 'pending',
      );

      try {
        await Provider.of<StudentProvider>(context, listen: false).addStudent(student);
        
        if (mounted) {
          // Update Auth state
          context.read<AuthProvider>().setAuthenticated(
            true, 
            role: 'student', 
            uid: student.uid
          );
          
          setState(() => _isLoading = false);
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful! Welcome Student.")),
          );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Registration"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role-selection');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              ),
              
              CustomTextField(
                controller: _regController,
                labelText: "Registration Number", 
                prefixIcon: Icons.badge_outlined,
                validator: AppValidators.validateRegistrationNumber,
              ),
              
              CustomTextField(
                controller: _phoneController,
                labelText: "Phone Number", 
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhone,
              ),
              
              CustomTextField(
                controller: _addressController,
                labelText: "Route Address", 
                prefixIcon: Icons.map_outlined,
                validator: (v) => AppValidators.validateRequired(v, "Route Address"),
              ),
              
              CustomTextField(
                controller: _emailController,
                labelText: "Email Address", 
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              
              CustomTextField(
                controller: _passController,
                labelText: "Password", 
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: AppValidators.validatePassword,
                maxLength: 20,
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
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
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
