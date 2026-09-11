import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';
import '../../core/validators/app_validators.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditStudentScreen extends StatefulWidget {
  final StudentModel? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _regController;
  late TextEditingController _deptController;
  late TextEditingController _semesterController;
  late TextEditingController _fatherController;
  late TextEditingController _dobController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _routeController;
  
  String _selectedGender = 'Male';
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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name);
    _rollNoController = TextEditingController(text: widget.student?.rollNo);
    _regController = TextEditingController(text: widget.student?.regNumber);
    _deptController = TextEditingController(text: widget.student?.department);
    _semesterController = TextEditingController(text: widget.student?.semester ?? '1');
    _fatherController = TextEditingController(text: widget.student?.fatherName);
    _dobController = TextEditingController(text: widget.student?.dob);
    _emailController = TextEditingController(text: widget.student?.email);
    _phoneController = TextEditingController(text: widget.student?.phone);
    _routeController = TextEditingController(text: widget.student?.routeAddress);
    _passwordController = TextEditingController();
    _selectedGender = widget.student?.gender ?? 'Male';
    if (_selectedGender.isEmpty) _selectedGender = 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _regController.dispose();
    _deptController.dispose();
    _semesterController.dispose();
    _fatherController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    String profileImageBase64 = widget.student?.profileImage ?? '';
    if (_webImage != null) {
      profileImageBase64 = base64Encode(_webImage!);
    }

    final student = StudentModel(
      uid: widget.student?.uid ?? DateTime.now().millisecondsSinceEpoch.toString(),
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: 'student',
      regNumber: _regController.text.trim(),
      fatherName: _fatherController.text.trim(),
      gender: _selectedGender,
      dob: _dobController.text.trim(),
      department: _deptController.text.trim(),
      semester: _semesterController.text.trim(),
      profileImage: profileImageBase64,
      routeAddress: _routeController.text.trim(),
      rollNo: _rollNoController.text.trim(),
      verificationStatus: widget.student?.verificationStatus ?? 'approved',
    );

    try {
      await Provider.of<StudentProvider>(context, listen: false).addStudent(student);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.student == null ? 'Student added successfully' : 'Student updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (widget.student?.profileImage != null && widget.student!.profileImage.isNotEmpty) {
      if (widget.student!.profileImage.startsWith('http')) {
        imageProvider = NetworkImage(widget.student!.profileImage);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(widget.student!.profileImage));
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.student == null ? 'Add Student' : 'Edit Student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _nameController, 
              labelText: 'Student Full Name',
              prefixIcon: Icons.person_outline,
              validator: AppValidators.validateFullName,
            ),
            CustomTextField(
              controller: _rollNoController, 
              labelText: 'Roll No',
              prefixIcon: Icons.format_list_numbered,
              validator: AppValidators.validateRollNo,
            ),
            CustomTextField(
              controller: _regController, 
              labelText: 'Registration Number (Optional)',
              prefixIcon: Icons.badge_outlined,
              validator: AppValidators.validateRegistrationNumber,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _deptController, 
                    labelText: 'Department',
                    prefixIcon: Icons.school_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _semesterController, 
                    labelText: 'Semester',
                    prefixIcon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            CustomTextField(
              controller: _fatherController, 
              labelText: 'Father\'s Name',
              prefixIcon: Icons.person_pin_outlined,
              validator: (v) => AppValidators.validateRequired(v, "Father's Name"),
            ),
            const Text('Gender', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: _selectedGender,
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                ),
              ],
            ),
            CustomTextField(
              controller: _dobController, 
              labelText: 'Date of Birth (YYYY-MM-DD)',
              prefixIcon: Icons.cake_outlined,
              validator: (v) => AppValidators.validateRequired(v, "Date of Birth"),
            ),
            CustomTextField(
              controller: _emailController, 
              labelText: 'Email Address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.validateEmail,
            ),
            CustomTextField(
              controller: _phoneController, 
              labelText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: AppValidators.validatePhone,
            ),
            CustomTextField(
              controller: _routeController, 
              labelText: 'Route Address',
              prefixIcon: Icons.map_outlined,
              validator: (v) => AppValidators.validateRequired(v, "Route Address"),
            ),
            if (widget.student == null)
              CustomTextField(
                controller: _passwordController, 
                labelText: 'Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                validator: AppValidators.validatePassword,
                maxLength: 20,
              ),
            const SizedBox(height: 32),
            CustomButton(
              text: widget.student == null ? 'ADD STUDENT' : 'UPDATE STUDENT', 
              isLoading: _isLoading,
              onPressed: _saveForm
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('CANCEL')
            ),
          ],
        ),
      ),
    );
  }
}
