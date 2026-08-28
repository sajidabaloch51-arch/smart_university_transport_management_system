import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({super.key});

  @override
  State<EditDriverProfileScreen> createState() => _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final driver = Provider.of<DriverProvider>(context, listen: false).driver;
    _nameController = TextEditingController(text: driver?.name ?? '');
    _phoneController = TextEditingController(text: driver?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      // Simulate save delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        // In a real app, you would update Firestore here.
        // For now, we'll just show a success message.
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: "Full Name",
                prefixIcon: Icons.person,
                validator: (v) => v!.isEmpty ? "Name is required" : null,
              ),
              CustomTextField(
                controller: _phoneController,
                labelText: "Phone Number",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Phone number is required" : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "SAVE CHANGES",
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
