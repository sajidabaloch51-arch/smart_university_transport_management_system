import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditDriverScreen extends StatefulWidget {
  const AddEditDriverScreen({super.key});

  @override
  State<AddEditDriverScreen> createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends State<AddEditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  
  String? _selectedBus;
  String? _selectedRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Driver')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _nameController, 
              labelText: 'Driver Full Name',
              prefixIcon: Icons.person,
            ),
            CustomTextField(
              controller: _idController, 
              labelText: 'Employee ID',
              prefixIcon: Icons.badge,
            ),
            CustomTextField(
              controller: _emailController, 
              labelText: 'Email Address',
              prefixIcon: Icons.email,
            ),
            CustomTextField(
              controller: _phoneController, 
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
            ),
            CustomTextField(
              controller: _passController, 
              labelText: 'Account Password',
              prefixIcon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedBus,
              decoration: InputDecoration(
                labelText: 'Assign Bus',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['UOG-001', 'UOG-002', 'UOG-003'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _selectedBus = v),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              decoration: InputDecoration(
                labelText: 'Assign Route',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Route A', 'Route B', 'Route C'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRoute = v),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'SAVE DRIVER', 
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
