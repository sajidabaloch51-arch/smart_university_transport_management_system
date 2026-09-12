import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../core/validators/app_validators.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetching = true;
  StudentModel? _currentStudent;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  void _fetchStudentData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    if (authProvider.uid != null) {
      final student = await studentProvider.getStudent(authProvider.uid!);
      if (mounted) {
        setState(() {
          _currentStudent = student;
          if (student != null) {
            _nameController.text = student.name;
            _phoneController.text = student.phone;
            _regController.text = student.regNumber;
            _addressController.text = student.routeAddress;
          }
          _isFetching = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentStudent == null) return;

    setState(() => _isLoading = true);
    
    final updatedStudent = StudentModel(
      uid: _currentStudent!.uid,
      name: _nameController.text.trim(),
      email: _currentStudent!.email,
      phone: _phoneController.text.trim(),
      role: _currentStudent!.role,
      regNumber: _regController.text.trim(),
      fatherName: _currentStudent!.fatherName,
      gender: _currentStudent!.gender,
      dob: _currentStudent!.dob,
      department: _currentStudent!.department,
      semester: _currentStudent!.semester,
      profileImage: _currentStudent!.profileImage,
      routeAddress: _addressController.text.trim(),
    );

    try {
      await Provider.of<StudentProvider>(context, listen: false).updateStudent(updatedStudent);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentStudent == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Personal Information')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile details.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchStudentData, 
                child: const Text('Retry')
              ),
            ],
          ),
        ),
      );
    }

    ImageProvider? imageProvider;
    if (_currentStudent!.profileImage.isNotEmpty) {
      if (_currentStudent!.profileImage.startsWith('http')) {
        imageProvider = NetworkImage(_currentStudent!.profileImage);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(_currentStudent!.profileImage));
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE3F2FD),
                    backgroundImage: imageProvider,
                    child: imageProvider == null 
                        ? const Icon(Icons.person, size: 50, color: Color(0xFF003366)) 
                        : null,
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF003366),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Change Profile Photo', style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),
              
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: AppValidators.validateFullName,
              ),
              
              CustomTextField(
                controller: _regController,
                labelText: 'Registration Number',
                prefixIcon: Icons.badge_outlined,
                validator: AppValidators.validateRegistrationNumber,
              ),
              
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhone,
              ),

              CustomTextField(
                controller: _addressController,
                labelText: 'Route Address',
                prefixIcon: Icons.map_outlined,
                validator: (v) => AppValidators.validateRequired(v, "Route Address"),
              ),
              
              const SizedBox(height: 16),
              _buildReadOnlyInfo('Email Address', _currentStudent!.email, Icons.email_outlined),
              _buildReadOnlyInfo('Department', _currentStudent!.department, Icons.school_outlined),
              
              const SizedBox(height: 40),
              CustomButton(
                text: 'SAVE CHANGES',
                isLoading: _isLoading,
                onPressed: _saveChanges,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
