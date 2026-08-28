import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _termsAccepted = false;

  final List<String> _departments = [
    "BS Information Technology", "BS Computer Science", "BS Software Engineering", 
    "BS BBA", "BS Economics", "BS Chemistry", "BS Commerce"
  ];

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
                labelText: "Registration Number", 
                prefixIcon: Icons.badge,
                validator: (v) => AppValidators.validateRequired(v, "Registration Number"),
              ),
              CustomTextField(
                labelText: "Full Name", 
                prefixIcon: Icons.person,
                validator: (v) => AppValidators.validateRequired(v, "Full Name"),
              ),
              CustomTextField(
                labelText: "Father Name", 
                prefixIcon: Icons.person_outline,
                validator: (v) => AppValidators.validateRequired(v, "Father Name"),
              ),
              
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Department"),
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) {},
              ),
              
              const SizedBox(height: 16),
              CustomTextField(
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
                isLoading: _isLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate() && _termsAccepted) {
                    setState(() => _isLoading = true);
                    // logic here
                  }
                },
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
