import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Hero(
                tag: 'auth_icon',
                child: Icon(Icons.directions_bus_rounded, size: 80, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 32),
              const Text(
                "University of Gwadar",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Smart Transport System",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              const CustomTextField(
                labelText: "Email", 
                prefixIcon: Icons.email_outlined,
              ),
              
              const CustomTextField(
                labelText: "Password", 
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v!)),
                      const Text("Remember Me", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text("Forgot Password?", style: TextStyle(fontSize: 12))
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              CustomButton(
                text: "LOGIN",
                isLoading: _isLoading,
                onPressed: () {
                  setState(() => _isLoading = true);
                  // Logic to check role and navigate
                },
              ),
              
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text("Sign in with Google"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen())),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
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
