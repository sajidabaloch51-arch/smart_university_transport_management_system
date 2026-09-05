import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';
import '../driver/driver_dashboard.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate API call for now (In a real app, use AuthService)
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const DriverDashboard()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Welcome to SUTMS Driver Portal!")),
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
                validator: AppValidators.validateFullName,
              ),
              
              CustomTextField(
                controller: _idController,
                labelText: "Driver ID / Employee ID",
                prefixIcon: Icons.badge,
                validator: (v) => AppValidators.validateRequired(v, "Driver ID"),
              ),
              
              CustomTextField(
                controller: _phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhone,
              ),
              
              CustomTextField(
                controller: _emailController,
                labelText: "Email Address",
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              
              CustomTextField(
                controller: _passwordController,
                labelText: "Password",
                prefixIcon: Icons.lock,
                isPassword: true,
                maxLength: 20,
                validator: AppValidators.validatePassword,
              ),
              
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: "Confirm Password",
                prefixIcon: Icons.lock_reset,
                isPassword: true,
                maxLength: 20,
                validator: (v) => AppValidators.validateConfirmPassword(v, _passwordController.text),
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
