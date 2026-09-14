import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/driver_model.dart';
import '../../core/validators/app_validators.dart';
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
  late TextEditingController _licenseController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passController;
  
  String? _selectedBus;
  String? _selectedRoute;
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
    _nameController = TextEditingController(text: widget.driver?.name ?? '');
    _idController = TextEditingController(text: widget.driver?.driverId ?? '');
    _licenseController = TextEditingController(text: widget.driver?.licenseNumber ?? '');
    _emailController = TextEditingController(text: widget.driver?.email ?? '');
    _phoneController = TextEditingController(text: widget.driver?.phone ?? '');
    _passController = TextEditingController();
    
    // Safety check for dropdown values
    const buses = ['UOG-001', 'UOG-002', 'UOG-003'];
    const routes = ['Route A', 'Route B', 'Route C'];
    
    _selectedBus = buses.contains(widget.driver?.assignedBusNumber) 
        ? widget.driver?.assignedBusNumber 
        : null;
        
    _selectedRoute = routes.contains(widget.driver?.assignedRouteName) 
        ? widget.driver?.assignedRouteName 
        : null;
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

  void _saveDriver() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String profileImageBase64 = widget.driver?.profileImg ?? '';
      if (_webImage != null) {
        profileImageBase64 = base64Encode(_webImage!);
      }

      final driver = DriverModel(
        uid: widget.driver?.uid ?? (_emailController.text.trim().split('@')[0] + "_id"),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'driver',
        driverId: _idController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        profileImg: profileImageBase64,
        assignedBusId: widget.driver?.assignedBusId ?? '',
        assignedBusNumber: _selectedBus ?? 'Not Assigned',
        assignedRouteId: widget.driver?.assignedRouteId ?? '',
        assignedRouteName: _selectedRoute ?? 'Not Assigned',
        isOnDuty: widget.driver?.isOnDuty ?? false,
      );

      try {
        await Provider.of<DriverProvider>(context, listen: false).updateDriver(driver);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver ${widget.driver == null ? 'added' : 'updated'} successfully'), 
              backgroundColor: Colors.green
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
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (widget.driver?.profileImg != null && widget.driver!.profileImg.isNotEmpty) {
      if (widget.driver!.profileImg.startsWith('http')) {
        imageProvider = NetworkImage(widget.driver!.profileImg);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(widget.driver!.profileImg));
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.driver == null ? 'Add Driver' : 'Edit Driver')),
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
                      backgroundColor: Colors.green,
                      child: Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _nameController, 
              labelText: 'Driver Full Name',
              prefixIcon: Icons.person,
              validator: AppValidators.validateFullName,
            ),
            CustomTextField(
              controller: _idController, 
              labelText: 'Employee ID',
              prefixIcon: Icons.badge,
              validator: (v) => AppValidators.validateRequired(v, 'Employee ID'),
            ),
            CustomTextField(
              controller: _licenseController, 
              labelText: 'License Number (Optional)',
              prefixIcon: Icons.description,
              validator: AppValidators.validateBalochistanLicense,
            ),
            CustomTextField(
              controller: _emailController, 
              labelText: 'Email Address',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.validateEmail,
            ),
            CustomTextField(
              controller: _phoneController, 
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: AppValidators.validatePhone,
            ),
            if (widget.driver == null)
              CustomTextField(
                controller: _passController, 
                labelText: 'Account Password',
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: AppValidators.validatePassword,
                maxLength: 20,
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
              isLoading: _isLoading,
              onPressed: _saveDriver,
            ),
          ],
        ),
      ),
    );
  }
}
