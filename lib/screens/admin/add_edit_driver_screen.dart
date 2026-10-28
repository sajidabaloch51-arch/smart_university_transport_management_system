import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/validators/app_validators.dart';
import '../../models/bus_model.dart';
import '../../models/driver_model.dart';
import '../../models/route_model.dart';
import '../../providers/bus_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/route_provider.dart';
import '../../services/auth_service.dart';
import '../../services/autofill_policy.dart';
import '../../services/password_hasher.dart';
import '../../services/route_assignment_service.dart';
import '../../utils/email_validator.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

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
  /// Empty string = Not Assigned. Always store Firestore document ids.
  String _selectedRouteId = '';
  String _selectedBusId = '';
  bool _isLoading = false;
  bool _autofillFinished = false;
  bool _staleRouteWarned = false;
  bool _staleBusWarned = false;

  final _routeAssignment = RouteAssignmentService();

  List<RouteModel> _routes = const [];
  List<BusModel> _buses = const [];
  bool _routesLoading = true;
  bool _busesLoading = true;
  String? _routesError;
  String? _busesError;
  StreamSubscription<List<RouteModel>>? _routesSub;
  StreamSubscription<List<BusModel>>? _busesSub;

  Uint8List? _webImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _webImage = bytes);
    }
  }

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    AutofillPolicy.enableNormalAutofill();
    final d = widget.driver;
    _nameController = TextEditingController(text: d?.name ?? '');
    _idController = TextEditingController(text: d?.driverId ?? '');
    _emailController = TextEditingController(text: d?.email ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _experienceController = TextEditingController(
      text: d?.experienceYears?.toString() ?? '',
    );
    _passController = TextEditingController();
    _licenseController = TextEditingController(text: d?.licenseNumber ?? '');
    _status = d?.status ?? 'Active';

    final rid = (d?.assignedRouteId ?? '').trim();
    _selectedRouteId =
        (rid.isEmpty || rid.toLowerCase() == 'not assigned') ? '' : rid;
    final bid = (d?.assignedBusId ?? '').trim();
    _selectedBusId =
        (bid.isEmpty || bid.toLowerCase() == 'not assigned') ? '' : bid;

    final routeProvider = context.read<RouteProvider>();
    final busProvider = context.read<BusProvider>();
    _routes = List.of(routeProvider.cachedRoutes);
    _buses = List.of(busProvider.cachedBuses);
    _routesLoading = true;
    _busesLoading = true;

    // Live updates (after first paint).
    _routesSub = routeProvider.streamRoutes().listen(
      (list) {
        if (!mounted || list.isEmpty) return;
        setState(() {
          _routes = list;
          _routesLoading = false;
          _routesError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        // Keep any list already loaded via direct fetch.
        setState(() {
          _routesLoading = false;
          if (_routes.isEmpty) _routesError = '$e';
        });
      },
    );
    _busesSub = busProvider.streamBuses().listen(
      (list) {
        if (!mounted || list.isEmpty) return;
        setState(() {
          _buses = list;
          _busesLoading = false;
          _busesError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _busesLoading = false;
          if (_buses.isEmpty) _busesError = '$e';
        });
      },
    );

    // Direct Firestore get — fills Assign Route/Bus even if live stream hangs.
    // ignore: discarded_futures
    _bootstrapAssignmentDropdowns(routeProvider, busProvider);
  }

  Future<void> _bootstrapAssignmentDropdowns(
    RouteProvider routeProvider,
    BusProvider busProvider,
  ) async {
    // Fresh driver doc so Manage Routes / Duties assignments appear here.
    final existing = widget.driver;
    if (existing != null &&
        existing.uid.isNotEmpty &&
        Firebase.apps.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(existing.uid)
            .get()
            .timeout(const Duration(seconds: 6));
        if (doc.exists && doc.data() != null && mounted) {
          final fresh = DriverModel.fromMap(doc.data()!, doc.id);
          final rid = fresh.assignedRouteId.trim();
          final bid = fresh.assignedBusId.trim();
          setState(() {
            _selectedRouteId =
                (rid.isEmpty || rid.toLowerCase() == 'not assigned')
                    ? ''
                    : rid;
            _selectedBusId =
                (bid.isEmpty || bid.toLowerCase() == 'not assigned')
                    ? ''
                    : bid;
            _staleRouteWarned = false;
            _staleBusWarned = false;
          });
        }
      } catch (_) {}
    }

    try {
      final routes = await routeProvider.fetchAllRoutesForAssignment();
      if (mounted) {
        setState(() {
          if (routes.isNotEmpty) _routes = routes;
          _routesLoading = false;
          _routesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routesLoading = false;
          if (_routes.isEmpty) _routesError = '$e';
        });
      }
    }

    try {
      final buses = await busProvider.fetchAllBusesForAssignment();
      if (mounted) {
        setState(() {
          if (buses.isNotEmpty) _buses = buses;
          _busesLoading = false;
          _busesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busesLoading = false;
          if (_buses.isEmpty) _busesError = '$e';
        });
      }
    }
  }

  Future<void> _retryRoutes() async {
    setState(() {
      _routesLoading = true;
      _routesError = null;
    });
    final list =
        await context.read<RouteProvider>().fetchAllRoutesForAssignment();
    if (!mounted) return;
    setState(() {
      _routes = list;
      _routesLoading = false;
      _routesError = list.isEmpty ? 'No routes found' : null;
    });
  }

  Future<void> _retryBuses() async {
    setState(() {
      _busesLoading = true;
      _busesError = null;
    });
    final list =
        await context.read<BusProvider>().fetchAllBusesForAssignment();
    if (!mounted) return;
    setState(() {
      _buses = list;
      _busesLoading = false;
      _busesError = list.isEmpty ? 'No buses found' : null;
    });
  }

  Future<void> _finishAutofill({required bool shouldSave}) async {
    if (_autofillFinished) return;
    _autofillFinished = true;
    if (shouldSave) {
      await AutofillPolicy.commitSave();
    } else {
      await AutofillPolicy.cancelSave();
    }
  }

  @override
  void dispose() {
    if (!_autofillFinished) {
      TextInput.finishAutofillContext(shouldSave: false);
      _autofillFinished = true;
    }
    _routesSub?.cancel();
    _busesSub?.cancel();
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _showShareTempPasswordDialog(String tempPassword) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Share this securely'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temporary password (it will not be shown again). '
              'Share it securely with the driver — they must change it on first login.',
            ),
            const SizedBox(height: 12),
            SelectableText(
              tempPassword,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: tempPassword));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<bool> _licenseIsUnique(String license, String excludeUid) async {
    if (Firebase.apps.isEmpty) return true;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('licenseNumber', isEqualTo: license)
        .limit(5)
        .get();
    return snap.docs.every((d) => d.id == excludeUid);
  }

  Future<bool> _confirmReplaceIfNeeded({
    required String routeId,
    required String busId,
    required String driverId,
  }) async {
    if (Firebase.apps.isEmpty) return true;
    final db = FirebaseFirestore.instance;
    final warnings = <String>[];

    if (routeId.isNotEmpty) {
      final r = await db.collection('routes').doc(routeId).get();
      final other = r.data()?['driverId']?.toString() ?? '';
      if (other.isNotEmpty && other != driverId) {
        final name = r.data()?['driverName']?.toString() ?? other;
        warnings.add('This route is currently assigned to $name.');
      }
    }
    if (busId.isNotEmpty) {
      final b = await db.collection('buses').doc(busId).get();
      final other = b.data()?['assignedDriverId']?.toString() ?? '';
      if (other.isNotEmpty && other != driverId) {
        final name = b.data()?['assignedDriverName']?.toString() ?? other;
        warnings.add('This bus is currently assigned to $name.');
      }
    }
    if (warnings.isEmpty) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace existing assignment?'),
        content: Text(
          '${warnings.join('\n')}\n\n'
          'Continuing will clear the old driver and link this driver instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _saveDriver() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    var profileImageBase64 = widget.driver?.profileImg ?? '';
    if (_webImage != null) {
      profileImageBase64 = base64Encode(_webImage!);
    }

    final email = AppEmailValidator.normalize(_emailController.text);
    final isNew = widget.driver == null;
    var uid = widget.driver?.uid ?? '';
    String? passwordHash;
    final driverProvider = context.read<DriverProvider>();
    final license = _licenseController.text.trim();

    try {
      if (!await _licenseIsUnique(license, uid)) {
        throw Exception('License number is already used by another driver.');
      }
      if (!mounted) return;

      final tempPassword = isNew ? _passController.text : '';
      if (isNew) {
        try {
          // Secondary FirebaseApp — Admin Auth session stays intact.
          final authUser = await AuthService()
              .createUserKeepCurrentSession(email, tempPassword);
          uid = authUser.uid;
        } on AuthServiceException catch (e) {
          if (!AuthService.isConfigurationError(e)) rethrow;
          uid = '${email.split('@').first}_id';
          passwordHash = PasswordHasher.hash(tempPassword);
        }
      }
      if (!mounted) return;

      final proceed = await _confirmReplaceIfNeeded(
        routeId: _selectedRouteId,
        busId: _selectedBusId,
        driverId: uid,
      );
      if (!proceed) {
        // Auth user may already exist; do not save password to GPM on abort.
        await _finishAutofill(shouldSave: false);
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;

      // Profile fields first (without relying on stale assignment fields).
      final driver = DriverModel(
        uid: uid,
        name: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        role: 'driver',
        driverId: _idController.text.trim(),
        licenseNumber: license,
        cnicOrLicense: '',
        licenseExpiryDate: null,
        address: '',
        experienceYears: int.tryParse(_experienceController.text.trim()),
        status: _status,
        profileImg: profileImageBase64,
        assignedBusId: _selectedBusId,
        assignedBusNumber: 'Not Assigned',
        assignedRouteId: _selectedRouteId,
        assignedRouteName: 'Not Assigned',
        isOnDuty: widget.driver?.isOnDuty ?? false,
        mustChangePassword:
            isNew ? true : (widget.driver?.mustChangePassword ?? false),
        verificationStatus: 'approved',
      );

      await driverProvider.updateDriver(driver);

      if (Firebase.apps.isNotEmpty) {
        final extra = <String, dynamic>{
          'role': 'driver',
          'verificationStatus': 'approved',
          'status': driver.status,
          'licenseNumber': license,
          if (isNew) 'mustChangePassword': true,
          if (passwordHash != null) 'passwordHash': passwordHash,
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(extra, SetOptions(merge: true));
      }

      // Single source of truth — batch updates driver + route + bus.
      await _routeAssignment.assign(
        driverId: uid,
        driverName: driver.name,
        driverPhone: driver.phone,
        routeId: _selectedRouteId,
        busId: _selectedBusId,
      );

      if (!mounted) return;
      // Controllers still hold values — offer Save password for the NEW driver.
      if (isNew && tempPassword.isNotEmpty) {
        await _finishAutofill(shouldSave: true);
        if (!mounted) return;
        await _showShareTempPasswordDialog(tempPassword);
        if (!mounted) return;
      } else {
        await _finishAutofill(shouldSave: false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew
                ? 'Driver created. Share the temporary password securely.'
                : 'Driver updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      await _finishAutofill(shouldSave: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _safeRouteValue(List<RouteModel> routes) {
    if (_selectedRouteId.isEmpty) return '';
    if (routes.any((r) => r.id == _selectedRouteId)) return _selectedRouteId;
    // While still loading, keep the stored id so we don't wipe it prematurely.
    if (_routesLoading && routes.isEmpty) return '';
    if (!_staleRouteWarned) {
      _staleRouteWarned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedRouteId = '');
      });
    }
    return '';
  }

  String _safeBusValue(List<BusModel> buses) {
    if (_selectedBusId.isEmpty) return '';
    if (buses.any((b) => b.id == _selectedBusId)) return _selectedBusId;
    if (_busesLoading && buses.isEmpty) return '';
    if (!_staleBusWarned) {
      _staleBusWarned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedBusId = '');
      });
    }
    return '';
  }

  Widget _buildRouteDropdown() {
    final routes = _routes;
    if (routes.isEmpty && _routesError != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load routes. Check internet and retry.',
                style: TextStyle(color: Colors.red.shade800),
              ),
              TextButton.icon(
                onPressed: _retryRoutes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (routes.isEmpty && !_routesLoading) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No routes yet. Add a route first.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push('/manage-routes'),
                icon: const Icon(Icons.add_road),
                label: const Text('Manage Routes'),
              ),
              TextButton.icon(
                onPressed: _retryRoutes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry load'),
              ),
            ],
          ),
        ),
      );
    }

    final value = _safeRouteValue(routes);
    final stale = _staleRouteWarned &&
        (widget.driver?.assignedRouteId ?? '').isNotEmpty &&
        value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Assign Route',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _routesLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Not Assigned'),
            ),
            ...routes.map(
              (r) => DropdownMenuItem<String>(
                value: r.id,
                child: Text(
                  '${r.routeName}'
                  '${r.routeNumber.isNotEmpty ? ' (${r.routeNumber})' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedRouteId = v ?? ''),
        ),
        if (_routesLoading && routes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Loading routes…',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        if (stale)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Previous route no longer exists — reset to Not Assigned.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildBusDropdown() {
    final buses = _buses;
    if (buses.isEmpty && _busesError != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load buses. Check internet and retry.',
                style: TextStyle(color: Colors.red.shade800),
              ),
              TextButton.icon(
                onPressed: _retryBuses,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (buses.isEmpty && !_busesLoading) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No buses yet. Add a bus from Manage Buses first.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: _retryBuses,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry load'),
              ),
            ],
          ),
        ),
      );
    }

    final value = _safeBusValue(buses);
    final stale = _staleBusWarned &&
        (widget.driver?.assignedBusId ?? '').isNotEmpty &&
        value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Assign Bus',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _busesLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Not Assigned'),
            ),
            ...buses.map(
              (b) => DropdownMenuItem<String>(
                value: b.id,
                child: Text(
                  b.registrationNumber.trim().isEmpty
                      ? b.busNumber
                      : '${b.busNumber} · ${b.registrationNumber}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedBusId = v ?? ''),
        ),
        if (_busesLoading && buses.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Loading buses…',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        if (stale)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Previous bus no longer exists — reset to Not Assigned.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (widget.driver?.profileImg != null &&
        widget.driver!.profileImg.isNotEmpty) {
      if (widget.driver!.profileImg.startsWith('http')) {
        imageProvider = NetworkImage(widget.driver!.profileImg);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(widget.driver!.profileImg));
        } catch (e) {
          debugPrint('Error decoding base64 image: $e');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.driver == null ? 'Add Driver' : 'Edit Driver'),
      ),
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.commit,
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
                            ? const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green,
                        child:
                            Icon(Icons.edit, size: 16, color: Colors.white),
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
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateFullName,
                autofillHints: const [AutofillHints.name],
              ),
              CustomTextField(
                controller: _idController,
                labelText: 'Employee ID',
                prefixIcon: Icons.badge,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    AppValidators.validateRequired(v, 'Employee ID'),
              ),
              CustomTextField(
                controller: _licenseController,
                labelText: 'License Number',
                prefixIcon: Icons.credit_card,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    AppValidators.validateRequired(v, 'License Number'),
              ),
              CustomTextField(
                controller: _experienceController,
                labelText: 'Years of Experience',
                prefixIcon: Icons.history,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateExperienceYears,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Account Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Active', 'Inactive', 'On Leave']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                labelText: 'Driver email',
                hintText: AppEmailValidator.hint,
                helperText: AppEmailValidator.hint,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: AppValidators.validateEmail,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
              ),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: widget.driver == null
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: AppValidators.validatePhone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              if (widget.driver == null)
                CustomTextField(
                  controller: _passController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  validator: AppValidators.validatePassword,
                  maxLength: 20,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.newPassword],
                ),
              const SizedBox(height: 10),
              _buildRouteDropdown(),
              const SizedBox(height: 20),
              _buildBusDropdown(),
              const SizedBox(height: 40),
              CustomButton(
                text: widget.driver == null ? 'SAVE DRIVER' : 'UPDATE DRIVER',
                isLoading: _isLoading,
                onPressed: _saveDriver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
