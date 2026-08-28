import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController(text: 'Sajida Abdullah');
  final _phoneController = TextEditingController(text: '03091088710');
  final _regController = TextEditingController(text: 'UOG-2022-123');
  bool _isLoading = false;

  void _saveChanges() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.camera_alt, size: 40, color: Color(0xFF003366)),
            ),
            const SizedBox(height: 10),
            const Text('Change Photo', style: TextStyle(color: Color(0xFF003366))),
            const SizedBox(height: 30),
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _regController,
              label: 'Registration Number',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'SAVE CHANGES',
              isLoading: _isLoading,
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
