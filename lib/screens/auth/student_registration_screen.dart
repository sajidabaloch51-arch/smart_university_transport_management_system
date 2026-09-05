import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';
import '../../services/auth_service.dart';
import '../../models/student_model.dart';
import '../student/student_dashboard.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _routeController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
  bool _termsAccepted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _routeController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate() && _termsAccepted) {
      setState(() => _isLoading = true);
      
      try {
        final student = StudentModel(
          uid: '', 
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: 'student',
          regNumber: _regController.text.trim(),
          fatherName: 'Not Provided',
          gender: 'Not Specified',
          dob: 'Not Specified',
          department: 'Not Specified',
          semester: '1',
          profileImage: '',
          routeAddress: _routeController.text.trim(),
        );

        await _authService.registerStudent(student, _passController.text);

        if (mounted) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration Failed: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms and conditions")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              
              // 1. Full Name
              CustomTextField(
                controller: _nameController,
                labelText: "Full Name", 
                prefixIcon: Icons.person,
                validator: AppValidators.validateFullName,
              ),
              
              // 2. Registration Number
              CustomTextField(
                controller: _regController,
                labelText: "Registration Number", 
                prefixIcon: Icons.badge,
                validator: AppValidators.validateRegNo,
              ),
              
              // 3. Phone Number
              CustomTextField(
                controller: _phoneController,
                labelText: "Phone Number", 
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhone,
              ),
              
              // 4. Route Address
              CustomTextField(
                controller: _routeController,
                labelText: "Route Address (Pickup Location)", 
                hintText: "Enter your pickup address (e.g., Street 5, Gwadar)",
                prefixIcon: Icons.location_on,
                validator: (v) => AppValidators.validateRequired(v, "Route Address"),
              ),
              
              // 5. Email Address
              CustomTextField(
                controller: _emailController,
                labelText: "Email Address", 
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              
              // 6. Password
              CustomTextField(
                controller: _passController,
                labelText: "Password", 
                prefixIcon: Icons.lock,
                isPassword: true,
                maxLength: 20,
                validator: AppValidators.validatePassword,
              ),
              
              // 7. Confirm Password
              CustomTextField(
                controller: _confirmPassController,
                labelText: "Confirm Password", 
                prefixIcon: Icons.lock_reset,
                isPassword: true,
                maxLength: 20,
                validator: (v) => AppValidators.validateConfirmPassword(v, _passController.text),
              ),
              
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v!),
                title: const Text("I accept terms and conditions", style: TextStyle(fontSize: 12)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              const SizedBox(height: 30),
              CustomButton(
                text: "REGISTER",
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              
              const SizedBox(height: 20),
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
