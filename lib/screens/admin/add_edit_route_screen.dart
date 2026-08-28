import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../services/firestore_service.dart';

class AddEditRouteScreen extends StatefulWidget {
  final RouteModel? route;
  const AddEditRouteScreen({super.key, this.route});

  @override
  State<AddEditRouteScreen> createState() => _AddEditRouteScreenState();
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _distanceController;
  late TextEditingController _durationController;
  
  List<RouteStop> _stops = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.routeName ?? '');
    _numberController = TextEditingController(text: widget.route?.routeNumber ?? '');
    _startController = TextEditingController(text: widget.route?.startPoint ?? '');
    _endController = TextEditingController(text: widget.route?.endPoint ?? '');
    _distanceController = TextEditingController(text: widget.route?.totalDistance ?? '');
    _durationController = TextEditingController(text: widget.route?.estimatedDuration ?? '');
    _stops = widget.route?.stops ?? [];
  }

  void _addStop() {
    setState(() {
      _stops.add(RouteStop(stopName: '', lat: 0, lng: 0, order: _stops.length + 1));
    });
  }

  void _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    final newRoute = RouteModel(
      id: widget.route?.id ?? '',
      universityId: 'uog', // Default for now
      routeName: _nameController.text,
      routeNumber: _numberController.text,
      startPoint: _startController.text,
      endPoint: _endController.text,
      stops: _stops,
      totalDistance: _distanceController.text,
      estimatedDuration: _durationController.text,
    );

    await _firestoreService.addRoute(newRoute);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.route == null ? 'Add Route' : 'Edit Route')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Route Number (e.g., A)'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Route Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startController,
                    decoration: const InputDecoration(labelText: 'Start Point'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endController,
                    decoration: const InputDecoration(labelText: 'End Point'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._stops.asMap().entries.map((entry) {
              int idx = entry.key;
              return ListTile(
                title: TextFormField(
                  initialValue: _stops[idx].stopName,
                  decoration: InputDecoration(labelText: 'Stop ${idx + 1} Name'),
                  onChanged: (v) => _stops[idx] = RouteStop(
                    stopName: v,
                    lat: _stops[idx].lat,
                    lng: _stops[idx].lng,
                    order: _stops[idx].order,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _stops.removeAt(idx)),
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add),
              label: const Text('Add Stop'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('SAVE ROUTE'),
            ),
          ],
        ),
      ),
    );
  }
}
