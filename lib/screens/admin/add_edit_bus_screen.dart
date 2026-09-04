import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNoController;
  late TextEditingController _capacityController;
  late TextEditingController _regNoController;
  late TextEditingController _modelController;

  String? _selectedDriver;
  String? _selectedRoute;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _busNoController = TextEditingController(text: widget.bus?.busNumber ?? '');
    _capacityController = TextEditingController(text: widget.bus?.capacity.toString() ?? '');
    _regNoController = TextEditingController(text: widget.bus?.registrationNumber ?? '');
    _modelController = TextEditingController(text: widget.bus?.busModel ?? '');
    
    // Safety check for dropdown values
    const drivers = ['Nasir Ali', 'Ali Ahmed'];
    const routes = ['Route A', 'Route B'];
    
    _selectedDriver = drivers.contains(widget.bus?.assignedDriverName) 
        ? widget.bus?.assignedDriverName 
        : null;
        
    _selectedRoute = routes.contains(widget.bus?.assignedRouteName) 
        ? widget.bus?.assignedRouteName 
        : null;
  }

  @override
  void dispose() {
    _busNoController.dispose();
    _capacityController.dispose();
    _regNoController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveBus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final bus = BusModel(
        id: widget.bus?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        busNumber: _busNoController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        busModel: _modelController.text.trim(),
        registrationNumber: _regNoController.text.trim(),
        assignedDriverId: '',
        assignedDriverName: _selectedDriver ?? 'Not Assigned',
        assignedRouteId: '',
        assignedRouteName: _selectedRoute ?? 'Not Assigned',
        isActive: widget.bus?.isActive ?? true,
      );

      try {
        await Provider.of<BusProvider>(context, listen: false).addBus(bus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bus ${widget.bus == null ? 'registered' : 'updated'} successfully'), backgroundColor: Colors.green),
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
                controller: _capacityController, 
                labelText: 'Seating Capacity', 
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                controller: _modelController, 
                labelText: 'Bus Model / Year',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              CustomTextField(
                controller: _regNoController, 
                labelText: 'Legal Registration Number',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
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
