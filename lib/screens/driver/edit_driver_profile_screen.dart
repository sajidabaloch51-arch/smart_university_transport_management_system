import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/driver_model.dart';
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

  Uint8List? _webImage;
  XFile? _pickedFile;
  DriverModel? _currentDriver;

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
    _currentDriver = Provider.of<DriverProvider>(context, listen: false).driver;
    _nameController = TextEditingController(text: _currentDriver?.name ?? '');
    _phoneController = TextEditingController(text: _currentDriver?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_currentDriver == null) return;

      setState(() => _isSaving = true);
      
      String profileImageBase64 = _currentDriver!.profileImg;
      if (_webImage != null) {
        profileImageBase64 = base64Encode(_webImage!);
      }

      final updatedDriver = DriverModel(
        uid: _currentDriver!.uid,
        name: _nameController.text.trim(),
        email: _currentDriver!.email,
        phone: _phoneController.text.trim(),
        role: _currentDriver!.role,
        driverId: _currentDriver!.driverId,
        licenseNumber: _currentDriver!.licenseNumber,
        profileImg: profileImageBase64,
        assignedBusId: _currentDriver!.assignedBusId,
        assignedBusNumber: _currentDriver!.assignedBusNumber,
        assignedRouteId: _currentDriver!.assignedRouteId,
        assignedRouteName: _currentDriver!.assignedRouteName,
        isOnDuty: _currentDriver!.isOnDuty,
        lastDutyStart: _currentDriver!.lastDutyStart,
      );

      try {
        await Provider.of<DriverProvider>(context, listen: false).updateDriver(updatedDriver);
        
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update profile: $e"), backgroundColor: Colors.red),
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
    } else if (_currentDriver?.profileImg != null && _currentDriver!.profileImg.isNotEmpty) {
      if (_currentDriver!.profileImg.startsWith('http')) {
        imageProvider = NetworkImage(_currentDriver!.profileImg);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(_currentDriver!.profileImg));
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Change Profile Photo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),
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
