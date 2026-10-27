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
import '../../utils/email_validator.dart';
import '../../services/route_assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/password_hasher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
  late TextEditingController _licenseController;

  String _status = 'Active';
  String? _selectedBus;
  String? _selectedRoute;
  String? _selectedRouteId;
  bool _isLoading = false;
  final _routeAssignment = RouteAssignmentService();

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
    _licenseController = TextEditingController(
      text: widget.driver?.licenseNumber ?? '',
    );

    _status = widget.driver?.status ?? 'Active';

    _selectedBus = widget.driver?.assignedBusNumber;
    if (_selectedBus == 'Not Assigned') _selectedBus = null;

    _selectedRoute = widget.driver?.assignedRouteName;
    if (_selectedRoute == 'Not Assigned') _selectedRoute = null;
    _selectedRouteId = widget.driver?.assignedRouteId;
    if (_selectedRouteId != null && _selectedRouteId!.isEmpty) {
      _selectedRouteId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String profileImageBase64 = widget.driver?.profileImg ?? '';
    if (_webImage != null) {
      profileImageBase64 = base64Encode(_webImage!);
    }

    final email = AppEmailValidator.normalize(_emailController.text);
    final isNew = widget.driver == null;
    String uid = widget.driver?.uid ?? '';
    String? passwordHash;
    final driverProvider =
        Provider.of<DriverProvider>(context, listen: false);
    final routeProvider =
        Provider.of<RouteProvider>(context, listen: false);

    try {
      if (isNew) {
        final password = _passController.text;
        try {
          // Secondary FirebaseApp — Admin Auth session stays intact.
          final authUser = await AuthService()
              .createUserKeepCurrentSession(email, password);
          uid = authUser.uid;
        } on AuthServiceException catch (e) {
          if (!AuthService.isConfigurationError(e)) rethrow;
          uid = '${email.split('@').first}_id';
          passwordHash = PasswordHasher.hash(password);
          debugPrint(
            'Firebase Auth not configured — driver passwordHash fallback.',
          );
        }
      }

      final driver = DriverModel(
        uid: uid,
        name: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        role: 'driver',
        driverId: _idController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
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
        mustChangePassword: isNew ? true : (widget.driver?.mustChangePassword ?? false),
        verificationStatus: 'approved',
      );

      final routesList = await routeProvider.streamRoutes().first;

      RouteModel? matchedRoute;
      if (_selectedRouteId != null && _selectedRouteId!.isNotEmpty) {
        final hits = routesList.where((r) => r.id == _selectedRouteId);
        if (hits.isNotEmpty) matchedRoute = hits.first;
      }
      if (matchedRoute == null &&
          _selectedRoute != null &&
          _selectedRoute != 'Not Assigned') {
        final hits =
            routesList.where((r) => r.routeName == _selectedRoute);
        if (hits.isNotEmpty) matchedRoute = hits.first;
      }

      final correctedDriver = matchedRoute == null
          ? driver.copyWith(
              assignedRouteId: '',
              assignedRouteName: 'Not Assigned',
            )
          : driver.copyWith(
              assignedRouteId: matchedRoute.id,
              assignedRouteName: matchedRoute.routeName,
            );

      await driverProvider.updateDriver(correctedDriver);

      // Extra fields for new drivers (passwordHash fallback + approval).
      if (Firebase.apps.isNotEmpty) {
        final extra = <String, dynamic>{
          'role': 'driver',
          'verificationStatus': 'approved',
          'status': correctedDriver.status,
          if (isNew) 'mustChangePassword': true,
          if (passwordHash != null) 'passwordHash': passwordHash,
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(correctedDriver.uid)
            .set(extra, SetOptions(merge: true));
      }

      final previousRouteId = widget.driver?.assignedRouteId;
      if (matchedRoute != null) {
        await _routeAssignment.assignDriverToRoute(
          routeId: matchedRoute.id,
          driverId: correctedDriver.uid,
          driverName: correctedDriver.name,
          driverPhone: correctedDriver.phone,
          busNo: correctedDriver.assignedBusNumber == 'Not Assigned'
              ? ''
              : correctedDriver.assignedBusNumber,
        );
      } else if (previousRouteId != null && previousRouteId.isNotEmpty) {
        await _routeAssignment.unassignDriverFromRoute(previousRouteId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew
                  ? 'Driver created. They can log in with the temporary password.'
                  : 'Driver updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              labelText: 'License Number',
              prefixIcon: Icons.credit_card,
              validator: (v) =>
                  AppValidators.validateRequired(v, 'License Number'),
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
              hintText: AppEmailValidator.hint,
              helperText: AppEmailValidator.hint,
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
                labelText: 'Temporary Password',
                helperText:
                    'Driver must change this password after first login.',
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
                // Dropdown value = routeId (stable), not display name.
                String? currentId = _selectedRouteId;
                if (currentId != null &&
                    !routes.any((r) => r.id == currentId)) {
                  final byName = routes
                      .where((r) => r.routeName == _selectedRoute)
                      .toList();
                  currentId = byName.isEmpty ? null : byName.first.id;
                }

                return DropdownButtonFormField<String>(
                  initialValue: currentId,
                  decoration: InputDecoration(
                    labelText: 'Assign Route',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Not Assigned'),
                    ),
                    ...routes.map(
                      (r) => DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(r.routeName),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null || v.isEmpty) {
                      setState(() {
                        _selectedRouteId = null;
                        _selectedRoute = null;
                      });
                      return;
                    }
                    final match =
                        routes.where((r) => r.id == v).toList();
                    setState(() {
                      _selectedRouteId = v;
                      _selectedRoute =
                          match.isEmpty ? null : match.first.routeName;
                    });
                  },
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
