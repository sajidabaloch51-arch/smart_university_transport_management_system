import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../core/validators/app_validators.dart';
import '../../models/driver_model.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
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
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      String profileImageBase64 = '';
      if (_webImage != null) {
        profileImageBase64 = base64Encode(_webImage!);
      }

      final driverId = _emailController.text.trim().split('@')[0] + "_id";
      final driver = DriverModel(
        uid: driverId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'driver',
        driverId: _cnicController.text.trim(), // Using CNIC as placeholder ID
        profileImg: profileImageBase64,
        assignedBusId: '',
        assignedBusNumber: 'Not Assigned',
        assignedRouteId: '',
        assignedRouteName: 'Not Assigned',
        isOnDuty: false,
      );

      try {
        await Provider.of<DriverProvider>(context, listen: false).updateDriver(driver);
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          final prefs = await SharedPreferences.getInstance();
          const roleKey = 'saved_emails_driver';
          List<String> emails = prefs.getStringList(roleKey) ?? [];
          if (!emails.contains(driver.email)) {
            emails.add(driver.email);
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
                  Text("Driver Registered"),
                ],
              ),
              content: const Text(
                "Your driver account has been successfully registered. "
                "Please log in with your credentials to start your duty and manage trips."
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => context.go('/login', extra: 'driver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/role-selection');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Driver Registration"),
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
                            backgroundColor: const Color(0xFFE8F5E9),
                            backgroundImage: imageProvider,
                            child: imageProvider == null 
                                ? const Icon(Icons.drive_eta_rounded, size: 50, color: Colors.green)
                                : null,
                          ),
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Upload Driver Photo",
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
                    controller: _cnicController,
                    labelText: "CNIC Number",
                    prefixIcon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    validator: AppValidators.validateCNIC,
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
                    autofillHints: const [AutofillHints.email, AutofillHints.newUsername],
                  ),
                  
                  CustomTextField(
                    controller: _passwordController,
                    labelText: "Password",
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: AppValidators.validatePassword,
                    maxLength: 20,
                    autofillHints: const [AutofillHints.newPassword],
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
        ),
      ),
    );
  }
}
