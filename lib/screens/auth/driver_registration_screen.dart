import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedGender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Registration")),
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
                controller: _nameController,
                labelText: "Full Name",
                prefixIcon: Icons.person,
                validator: (v) => AppValidators.validateRequired(v, "Full Name"),
              ),
              CustomTextField(
                controller: _idController,
                labelText: "Driver ID",
                prefixIcon: Icons.badge,
                validator: (v) => AppValidators.validateRequired(v, "Driver ID"),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: "Gender"),
                items: ["Male", "Female"].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cnicController,
                labelText: "CNIC Number",
                prefixIcon: Icons.credit_card,
                validator: (v) => AppValidators.validateRequired(v, "CNIC"),
              ),
              CustomTextField(
                controller: _licenseController,
                labelText: "License Number",
                prefixIcon: Icons.drive_eta,
                validator: (v) => AppValidators.validateRequired(v, "License"),
              ),
              CustomTextField(
                controller: _phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone,
                validator: (v) => AppValidators.validateRequired(v, "Phone Number"),
              ),
              CustomTextField(
                controller: _emailController,
                labelText: "Gmail Address",
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              CustomTextField(
                controller: _passwordController,
                labelText: "Password",
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: AppValidators.validatePassword,
              ),
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: "Confirm Password",
                prefixIcon: Icons.lock_reset,
                isPassword: true,
                validator: (v) => AppValidators.validateConfirmPassword(v, _passwordController.text),
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: "REGISTER",
                isLoading: _isLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
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
