import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';
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
  final _fatherController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _termsAccepted = false;

  final List<String> _departments = [
    "BS Information Technology", "BS Computer Science", "BS Software Engineering", 
    "BS BBA", "BS Economics", "BS Chemistry", "BS Commerce"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _fatherController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate() && _termsAccepted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful! Welcome Student.")),
      );
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
              CustomTextField(
                controller: _regController,
                labelText: "Registration Number", 
                prefixIcon: Icons.badge,
                validator: (v) => AppValidators.validateRequired(v, "Registration Number"),
              ),
              CustomTextField(
                controller: _nameController,
                labelText: "Full Name", 
                prefixIcon: Icons.person,
                validator: (v) => AppValidators.validateRequired(v, "Full Name"),
              ),
              CustomTextField(
                controller: _fatherController,
                labelText: "Father Name", 
                prefixIcon: Icons.person_outline,
                validator: (v) => AppValidators.validateRequired(v, "Father Name"),
              ),
              
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Department"),
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) {},
                validator: (v) => v == null ? "Select Department" : null,
              ),
              
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: "Gmail Address", 
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              
              CustomTextField(
                controller: _passController,
                labelText: "Password", 
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: AppValidators.validatePassword,
              ),
              CustomTextField(
                labelText: "Confirm Password", 
                prefixIcon: Icons.lock_reset,
                isPassword: true,
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
