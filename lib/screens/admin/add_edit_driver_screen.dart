import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/bus_provider.dart';
import '../../models/driver_model.dart';
import '../../models/route_model.dart';
import '../../models/bus_model.dart';
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
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passController;
  late TextEditingController _experienceController;
  
  String _status = 'Active';
  String? _selectedBus;
  String? _selectedRoute;
  bool _isLoading = false;

  Uint8List? _webImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver?.name ?? '');
    _idController = TextEditingController(text: widget.driver?.driverId ?? '');
    _emailController = TextEditingController(text: widget.driver?.email ?? '');
    _phoneController = TextEditingController(text: widget.driver?.phone ?? '');
    _experienceController = TextEditingController(text: widget.driver?.experienceYears?.toString() ?? '');
    _passController = TextEditingController();
    
    _status = widget.driver?.status ?? 'Active';
    
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
    _experienceController.dispose();
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
        uid: widget.driver?.uid ?? ("${_emailController.text.trim().split('@')[0]}_id"),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'driver',
        driverId: _idController.text.trim(),
        licenseNumber: '',
        cnicOrLicense: '',
        licenseExpiryDate: null,
        address: '',
        experienceYears: int.tryParse(_experienceController.text.trim()),
        status: _status,
        profileImg: profileImageBase64,
        assignedBusId: widget.driver?.assignedBusId ?? '',
        assignedBusNumber: _selectedBus ?? 'Not Assigned',
        assignedRouteId: widget.driver?.assignedRouteId ?? '',
        assignedRouteName: _selectedRoute ?? 'Not Assigned',
        isOnDuty: widget.driver?.isOnDuty ?? false,
      );

      try {
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        
        // If a specific route name was selected in the form, resolve its ID from RouteProvider
        if (_selectedRoute != null && _selectedRoute != 'Not Assigned') {
          try {
            final routeProvider = Provider.of<RouteProvider>(context, listen: false);
            final routesList = await routeProvider.streamRoutes().first;
            final matchedRoute = routesList.firstWhere((r) => r.routeName == _selectedRoute);
            
            // Re-create the driver model with correct route mappings resolved dynamically
            final correctedDriver = DriverModel(
              uid: driver.uid,
              name: driver.name,
              email: driver.email,
              phone: driver.phone,
              role: driver.role,
              driverId: driver.driverId,
              licenseNumber: driver.licenseNumber,
              cnicOrLicense: driver.cnicOrLicense,
              licenseExpiryDate: driver.licenseExpiryDate,
              address: driver.address,
              experienceYears: driver.experienceYears,
              status: driver.status,
              profileImg: driver.profileImg,
              assignedBusId: driver.assignedBusId,
              assignedBusNumber: driver.assignedBusNumber,
              assignedRouteId: matchedRoute.id,
              assignedRouteName: matchedRoute.routeName,
              isOnDuty: driver.isOnDuty,
            );
            await driverProvider.updateDriver(correctedDriver);
          } catch (_) {
            await driverProvider.updateDriver(driver);
          }
        } else {
          await driverProvider.updateDriver(driver);
        }
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
              controller: _experienceController,
              labelText: 'Years of Experience',
              prefixIcon: Icons.history,
              keyboardType: TextInputType.number,
              validator: (v) => AppValidators.validateRequired(v, 'Experience'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Account Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Active', 'Inactive', 'On Leave'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 20),
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
            StreamBuilder<List<BusModel>>(
              stream: Provider.of<BusProvider>(context).streamBuses(),
              builder: (context, snapshot) {
                final buses = snapshot.data ?? [];
                final busItems = ['Not Assigned', ...buses.map((b) => b.busNumber)];
                
                String? currentBusVal = _selectedBus;
                if (currentBusVal != null && !busItems.contains(currentBusVal)) {
                  currentBusVal = null;
                }
                
                return DropdownButtonFormField<String>(
                  initialValue: currentBusVal,
                  decoration: InputDecoration(
                    labelText: 'Assign Bus',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: busItems.map((b) => DropdownMenuItem<String>(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() => _selectedBus = v == 'Not Assigned' ? null : v),
                );
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<RouteModel>>(
              stream: Provider.of<RouteProvider>(context).streamRoutes(),
              builder: (context, snapshot) {
                final routes = snapshot.data ?? [];
                final routeItems = ['Not Assigned', ...routes.map((r) => r.routeName)];
                
                // Keep selected value safe within item boundaries
                String? currentVal = _selectedRoute;
                if (currentVal != null && !routeItems.contains(currentVal)) {
                  currentVal = null;
                }
                
                return DropdownButtonFormField<String>(
                  initialValue: currentVal,
                  decoration: InputDecoration(
                    labelText: 'Assign Route',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: routeItems.map((r) => DropdownMenuItem<String>(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRoute = v == 'Not Assigned' ? null : v),
                );
              },
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
