import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import 'package:provider/provider.dart';
import '../../providers/route_provider.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditRouteScreen extends StatefulWidget {
  final RouteModel? route;
  const AddEditRouteScreen({super.key, this.route});

  @override
  State<AddEditRouteScreen> createState() => _AddEditRouteScreenState();
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _distController;
  late TextEditingController _durController;

  List<TextEditingController> _stopControllers = [];
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.routeName ?? '');
    _numberController = TextEditingController(text: widget.route?.routeNumber ?? '');
    _startController = TextEditingController(text: widget.route?.startLocation ?? '');
    _endController = TextEditingController(text: widget.route?.endLocation ?? '');
    _distController = TextEditingController(text: widget.route?.distanceKm ?? '');
    _durController = TextEditingController(text: widget.route?.estimatedTime ?? '');
    _isActive = widget.route?.isActive ?? true;
    
    if (widget.route != null) {
      _stopControllers = widget.route!.viaStops.map((s) => TextEditingController(text: s)).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _startController.dispose();
    _endController.dispose();
    _distController.dispose();
    _durController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() => _stopControllers.add(TextEditingController()));
  }

  void _saveRoute() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final routeId = widget.route?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final route = RouteModel(
        id: routeId,
        universityId: 'uog',
        routeName: _nameController.text.trim(),
        routeNumber: _numberController.text.trim(),
        startLocation: _startController.text.trim(),
        endLocation: _endController.text.trim(),
        distanceKm: _distController.text.trim(),
        estimatedTime: _durController.text.trim(),
        viaStops: _stopControllers.map((e) => e.text.trim()).toList(),
        stops: [],
        isActive: _isActive,
      );

      try {
        await Provider.of<RouteProvider>(context, listen: false).addRoute(route);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Route ${widget.route == null ? 'added' : 'updated'} successfully'), backgroundColor: Colors.green),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.route == null ? 'Add Route' : 'Edit Route')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _numberController, 
                labelText: 'Route Number (e.g., A)',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                controller: _nameController, 
                labelText: 'Route Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _startController, 
                      labelText: 'Start Location',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _endController, 
                      labelText: 'End Location',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _distController, 
                      labelText: 'Distance (km)',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _durController, 
                      labelText: 'Duration (min)',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Route Active'),
                subtitle: Text(_isActive ? 'Route is ON / available' : 'Route is OFF / inactive'),
                value: _isActive,
                activeThumbColor: Colors.green,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const Divider(height: 40),
              const Text('Via Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...List.generate(_stopControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stopControllers[index],
                          validator: (v) => v!.isEmpty ? 'Stop name required' : null,
                          decoration: InputDecoration(
                            hintText: 'Enter stop name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setState(() {
                          _stopControllers[index].dispose();
                          _stopControllers.removeAt(index);
                        }),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addStop, 
                icon: const Icon(Icons.add_location_alt), 
                label: const Text('ADD STOP')
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: widget.route == null ? 'SAVE ROUTE' : 'UPDATE ROUTE', 
                isLoading: _isLoading,
                onPressed: _saveRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
