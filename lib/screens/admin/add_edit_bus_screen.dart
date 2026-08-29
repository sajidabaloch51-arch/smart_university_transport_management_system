import 'package:flutter/material.dart';
import '../../models/bus_model.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditBusScreen extends StatefulWidget {
  final BusModel? bus;
  const AddEditBusScreen({super.key, this.bus});

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  late TextEditingController _busNoController;
  late TextEditingController _capacityController;
  late TextEditingController _regNoController;
  late TextEditingController _modelController;

  String? _selectedDriver;
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _busNoController = TextEditingController(text: widget.bus?.busNumber ?? '');
    _capacityController = TextEditingController(text: widget.bus?.capacity.toString() ?? '');
    _regNoController = TextEditingController(text: widget.bus?.registrationNumber ?? '');
    _modelController = TextEditingController(text: widget.bus?.busModel ?? '');
    _selectedDriver = widget.bus?.assignedDriverName;
    _selectedRoute = widget.bus?.assignedRouteName;
  }

  @override
  void dispose() {
    _busNoController.dispose();
    _capacityController.dispose();
    _regNoController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bus == null ? 'Add Bus' : 'Edit Bus')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(controller: _busNoController, labelText: 'Bus Number (e.g., UOG-001)'),
            CustomTextField(controller: _capacityController, labelText: 'Seating Capacity', keyboardType: TextInputType.number),
            CustomTextField(controller: _modelController, labelText: 'Bus Model / Year'),
            CustomTextField(controller: _regNoController, labelText: 'Legal Registration Number'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedDriver,
              decoration: InputDecoration(labelText: 'Assign Driver', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Nasir Ali', 'Ali Ahmed'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _selectedDriver = v),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              decoration: InputDecoration(labelText: 'Assign Route', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Route A', 'Route B'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRoute = v),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: widget.bus == null ? 'REGISTER BUS' : 'UPDATE BUS', 
              onPressed: () => Navigator.pop(context)
            ),
          ],
        ),
      ),
    );
  }
}
