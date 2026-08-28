import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class AddEditBusScreen extends StatefulWidget {
  const AddEditBusScreen({super.key});

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  final _busNoController = TextEditingController();
  final _capacityController = TextEditingController();
  final _regNoController = TextEditingController();
  final _modelController = TextEditingController();

  String? _selectedDriver;
  String? _selectedRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Bus')),
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
              decoration: InputDecoration(labelText: 'Assign Driver', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Nasir Ali', 'Ali Ahmed'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _selectedDriver = v),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Assign Route', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Route A', 'Route B'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRoute = v),
            ),
            const SizedBox(height: 40),
            CustomButton(text: 'REGISTER BUS', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
