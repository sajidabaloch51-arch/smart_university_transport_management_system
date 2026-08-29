import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditDriverScreen extends StatefulWidget {
  final DriverModel? driver;
  const AddEditDriverScreen({super.key, this.driver});

  @override
  State<AddEditDriverScreen> createState() => _AddEditDriverScreenState();
}

class _AddEditDriverScreenState extends State<AddEditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passController;
  
  String? _selectedBus;
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver?.name ?? '');
    _idController = TextEditingController(text: widget.driver?.driverId ?? '');
    _emailController = TextEditingController(text: widget.driver?.email ?? '');
    _phoneController = TextEditingController(text: widget.driver?.phone ?? '');
    _passController = TextEditingController();
    _selectedBus = widget.driver?.assignedBusNumber;
    _selectedRoute = widget.driver?.assignedRouteName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.driver == null ? 'Add Driver' : 'Edit Driver')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              controller: _nameController, 
              labelText: 'Driver Full Name',
              prefixIcon: Icons.person,
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            CustomTextField(
              controller: _idController, 
              labelText: 'Employee ID',
              prefixIcon: Icons.badge,
              validator: (v) => v!.isEmpty ? 'ID required' : null,
            ),
            CustomTextField(
              controller: _emailController, 
              labelText: 'Email Address',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Email required' : null,
            ),
            CustomTextField(
              controller: _phoneController, 
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Phone required' : null,
            ),
            if (widget.driver == null)
              CustomTextField(
                controller: _passController, 
                labelText: 'Account Password',
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (v) => v!.length < 6 ? 'Password too short' : null,
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
              text: widget.driver == null ? 'SAVE DRIVER' : 'UPDATE DRIVER',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
