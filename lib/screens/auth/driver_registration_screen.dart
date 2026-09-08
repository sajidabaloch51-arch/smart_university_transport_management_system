import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/driver-dashboard');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful! Welcome Driver.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.drive_eta_rounded, size: 50, color: Colors.green),
                ),
              ),
              const SizedBox(height: 32),
              
              CustomTextField(
                controller: _nameController,
                labelText: "Full Name",
                prefixIcon: Icons.person_outline,
                validator: AppValidators.validateFullName,
              ),
              
              CustomTextField(
                controller: _cnicController,
                labelText: "CNIC Number",
                prefixIcon: Icons.credit_card_outlined,
                validator: (v) => AppValidators.validateRequired(v, "CNIC Number"),
              ),
              
              CustomTextField(
                controller: _licenseController,
                labelText: "License Number",
                prefixIcon: Icons.badge_outlined,
                validator: (v) => AppValidators.validateRequired(v, "License Number"),
              ),
              
              CustomTextField(
                controller: _phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhone,
              ),
              
              CustomTextField(
                controller: _emailController,
                labelText: "Email Address",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              
              CustomTextField(
                controller: _passwordController,
                labelText: "Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: AppValidators.validatePassword,
                maxLength: 20,
              ),
              
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: "Confirm Password",
                prefixIcon: Icons.lock_reset_outlined,
                isPassword: true,
                validator: (v) => AppValidators.validateConfirmPassword(v, _passwordController.text),
                maxLength: 20,
              ),
              
              const SizedBox(height: 32),
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
                    onTap: () => context.pop(),
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
