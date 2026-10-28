import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bus_model.dart';
import '../../models/driver_model.dart';
import '../../models/route_model.dart';
import '../../providers/bus_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/route_provider.dart';
import '../../services/route_assignment_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditBusScreen extends StatefulWidget {
  final BusModel? bus;
  const AddEditBusScreen({super.key, this.bus});

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNoController;
  late TextEditingController _regNoController;

  bool _isLoading = false;
  bool _isActive = true;
  String _selectedDriverId = '';
  String _selectedRouteId = '';

  late final Stream<List<DriverModel>> _driversStream;
  late final Stream<List<RouteModel>> _routesStream;
  final _assignment = RouteAssignmentService();

  @override
  void initState() {
    super.initState();
    _busNoController =
        TextEditingController(text: widget.bus?.busNumber ?? '');
    _regNoController =
        TextEditingController(text: widget.bus?.registrationNumber ?? '');
    _isActive = widget.bus?.isActive ?? true;
    _selectedDriverId = widget.bus?.assignedDriverId.trim() ?? '';
    _selectedRouteId = widget.bus?.assignedRouteId.trim() ?? '';
    final drivers = context.read<DriverProvider>();
    final routes = context.read<RouteProvider>();
    _driversStream = drivers.streamDrivers();
    _routesStream = routes.streamRoutes();
    // ignore: discarded_futures
    drivers.refreshDrivers();
    // ignore: discarded_futures
    routes.refreshRoutes();
  }

  @override
  void dispose() {
    _busNoController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  Future<bool> _confirmReplace(String driverId) async {
    final bus = widget.bus;
    if (bus == null) return true;
    final prev = bus.assignedDriverId.trim();
    if (prev.isEmpty || prev == driverId) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace existing assignment?'),
        content: Text(
          'This bus is currently assigned to ${bus.assignedDriverName.isEmpty ? prev : bus.assignedDriverName}. '
          'Continue to reassign?',
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

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final busId = widget.bus?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final bus = BusModel(
      id: busId,
      busNumber: _busNoController.text.trim(),
      registrationNumber: _regNoController.text.trim(),
      assignedDriverId: widget.bus?.assignedDriverId ?? '',
      assignedDriverName: widget.bus?.assignedDriverName ?? '',
      assignedRouteId: widget.bus?.assignedRouteId ?? '',
      assignedRouteName: widget.bus?.assignedRouteName ?? '',
      isActive: _isActive,
    );

    try {
      await context.read<BusProvider>().addBus(bus);

      if (_selectedDriverId.isNotEmpty) {
        final proceed = await _confirmReplace(_selectedDriverId);
        if (!proceed) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        final drivers = await _driversStream.first;
        final match =
            drivers.where((d) => d.uid == _selectedDriverId).toList();
        final name = match.isEmpty ? '' : match.first.name;
        final phone = match.isEmpty ? '' : match.first.phone;
        await _assignment.assign(
          driverId: _selectedDriverId,
          driverName: name,
          driverPhone: phone,
          routeId: _selectedRouteId,
          busId: busId,
        );
      } else if ((widget.bus?.assignedDriverId ?? '').isNotEmpty) {
        await _assignment.assign(
          driverId: widget.bus!.assignedDriverId,
          driverName: widget.bus!.assignedDriverName,
          driverPhone: '',
          routeId: '',
          busId: '',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bus ${widget.bus == null ? 'registered' : 'updated'} successfully',
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.bus == null ? 'Add Bus' : 'Edit Bus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _busNoController,
                labelText: 'Bus Number (e.g., UOG-001)',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                controller: _regNoController,
                labelText: 'Registration Number / Plate (optional)',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bus Active'),
                subtitle: Text(
                  _isActive ? 'Bus is ON / available' : 'Bus is OFF / inactive',
                ),
                value: _isActive,
                activeThumbColor: Colors.green,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<DriverModel>>(
                stream: _driversStream,
                initialData: context.read<DriverProvider>().cachedDrivers.isEmpty
                    ? null
                    : context.read<DriverProvider>().cachedDrivers,
                builder: (context, snapshot) {
                  final drivers = snapshot.data ??
                      context.read<DriverProvider>().cachedDrivers;
                  var value = _selectedDriverId;
                  if (value.isNotEmpty &&
                      !drivers.any((d) => d.uid == value)) {
                    value = '';
                  }
                  return DropdownButtonFormField<String>(
                    value: value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Assign Driver',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              drivers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Not Assigned'),
                      ),
                      ...drivers.map(
                        (d) => DropdownMenuItem(
                          value: d.uid,
                          child: Text(d.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedDriverId = v ?? ''),
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<RouteModel>>(
                stream: _routesStream,
                initialData: context.read<RouteProvider>().cachedRoutes.isEmpty
                    ? null
                    : context.read<RouteProvider>().cachedRoutes,
                builder: (context, snapshot) {
                  final routes = snapshot.data ??
                      context.read<RouteProvider>().cachedRoutes;
                  var value = _selectedRouteId;
                  if (value.isNotEmpty &&
                      !routes.any((r) => r.id == value)) {
                    value = '';
                  }
                  return DropdownButtonFormField<String>(
                    value: value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Assign Route',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              routes.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Not Assigned'),
                      ),
                      ...routes.map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            '${r.routeName}'
                            '${r.routeNumber.isNotEmpty ? ' (${r.routeNumber})' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedRouteId = v ?? ''),
                  );
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: widget.bus == null ? 'REGISTER BUS' : 'UPDATE BUS',
                isLoading: _isLoading,
                onPressed: _saveBus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
