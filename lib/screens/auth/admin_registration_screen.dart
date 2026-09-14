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
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/admin_model.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  
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
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      String profileImageBase64 = '';
      if (_webImage != null) {
        profileImageBase64 = base64Encode(_webImage!);
      }

      final admin = AdminModel(
        uid: _emailController.text.trim().split('@')[0] + "_admin_id",
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'admin',
        university: 'University of Gwadar',
        profilePhoto: profileImageBase64,
        employeeId: _employeeIdController.text.trim(),
      );

      try {
        await Provider.of<AdminProvider>(context, listen: false).addAdmin(admin);
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Requirement: Save email for auto-fill (Role Specific)
          final prefs = await SharedPreferences.getInstance();
          const roleKey = 'saved_emails_admin';
          List<String> emails = prefs.getStringList(roleKey) ?? [];
          if (!emails.contains(admin.email)) {
            emails.add(admin.email);
            await prefs.setStringList(roleKey, emails);
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text("Admin Account Created"),
                ],
              ),
              content: const Text(
                "Your administrator account has been successfully registered. "
                "Please log in with your official credentials to access the Admin Panel."
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => context.go('/login', extra: 'admin'),
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
        title: const Text("Admin Registration"),
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
                              ? const Icon(Icons.admin_panel_settings, size: 50, color: Color(0xFF1565C0))
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
                    "Upload Official Photo",
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
                  controller: _employeeIdController,
                  labelText: "Employee ID", 
                  prefixIcon: Icons.badge_outlined,
                  validator: AppValidators.validateEmployeeId,
                ),

                CustomTextField(
                  controller: _phoneController,
                  labelText: "Official Phone Number", 
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.validatePhone,
                ),
                
                CustomTextField(
                  controller: _emailController,
                  labelText: "Official Email (Gmail)", 
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
                
                const SizedBox(height: 24),
                CustomButton(
                  text: "CREATE ADMIN ACCOUNT",
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => context.go('/login', extra: 'admin'),
                      child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
