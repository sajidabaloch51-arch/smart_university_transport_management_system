import 'package:flutter/material.dart';
import '../../models/route_model.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditRouteScreen extends StatefulWidget {
  final RouteModel? route;
  const AddEditRouteScreen({super.key, this.route});

  @override
  State<AddEditRouteScreen> createState() => _AddEditRouteScreenState();
}

class _AddEditRouteScreenState extends State<AddEditRouteScreen> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _distController;
  late TextEditingController _durController;

  List<TextEditingController> _stopControllers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.routeName ?? '');
    _numberController = TextEditingController(text: widget.route?.routeNumber ?? '');
    _startController = TextEditingController(text: widget.route?.startPoint ?? '');
    _endController = TextEditingController(text: widget.route?.endPoint ?? '');
    _distController = TextEditingController(text: widget.route?.totalDistance ?? '');
    _durController = TextEditingController(text: widget.route?.estimatedDuration ?? '');
    
    if (widget.route != null) {
      _stopControllers = widget.route!.stops.map((s) => TextEditingController(text: s.stopName)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.route == null ? 'Add Route' : 'Edit Route')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(controller: _numberController, labelText: 'Route Number (e.g., A)'),
            CustomTextField(controller: _nameController, labelText: 'Route Name'),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _startController, labelText: 'Start Point')),
                const SizedBox(width: 16),
                Expanded(child: CustomTextField(controller: _endController, labelText: 'End Point')),
              ],
            ),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _distController, labelText: 'Distance (km)')),
                const SizedBox(width: 16),
                Expanded(child: CustomTextField(controller: _durController, labelText: 'Duration (min)')),
              ],
            ),
            const Divider(height: 40),
            const Text('Stops List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(_stopControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _stopControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Enter stop name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => _stopControllers.removeAt(index)),
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
              onPressed: () => Navigator.pop(context)
            ),
          ],
        ),
      ),
    );
  }
}
