import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../providers/student_provider.dart';
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
  late TextEditingController _regController;
  late TextEditingController _deptController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name);
    _regController = TextEditingController(text: widget.student?.regNumber);
    _deptController = TextEditingController(text: widget.student?.department);
    _emailController = TextEditingController(text: widget.student?.email);
    _phoneController = TextEditingController(text: widget.student?.phone);
    _passwordController = TextEditingController();
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final student = StudentModel(
      uid: widget.student?.uid ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      regNumber: _regController.text,
      department: _deptController.text,
      semester: '1', // Default
      email: _emailController.text,
      phone: _phoneController.text,
      profileImage: '',
    );

    try {
      await Provider.of<StudentProvider>(context, listen: false).addStudent(student);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.student == null ? 'Add Student' : 'Edit Student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
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
              labelText: 'Student Full Name',
              prefixIcon: Icons.person,
              validator: (v) => v!.isEmpty ? 'Enter name' : null,
            ),
            CustomTextField(
              controller: _regController, 
              labelText: 'Registration Number',
              prefixIcon: Icons.badge,
              validator: (v) => v!.isEmpty ? 'Enter Reg No' : null,
            ),
            CustomTextField(
              controller: _deptController, 
              labelText: 'Department',
              prefixIcon: Icons.school,
            ),
            CustomTextField(
              controller: _emailController, 
              labelText: 'Email Address',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            CustomTextField(
              controller: _phoneController, 
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            if (widget.student == null)
              CustomTextField(
                controller: _passwordController, 
                labelText: 'Password',
                prefixIcon: Icons.lock,
                isPassword: true,
              ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'SAVE STUDENT', 
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
