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
  late TextEditingController _regNoController;

  String? _selectedDriver;
  String? _selectedRoute;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _busNoController = TextEditingController(text: widget.bus?.busNumber ?? '');
    _regNoController = TextEditingController(text: widget.bus?.registrationNumber ?? '');
    
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
    _regNoController.dispose();
    super.dispose();
  }

  void _saveBus() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final bus = BusModel(
        id: widget.bus?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        busNumber: _busNoController.text.trim(),
        registrationNumber: widget.bus?.registrationNumber ?? '',
        assignedDriverId: '',
        assignedDriverName: 'Not Assigned',
        assignedRouteId: '',
        assignedRouteName: 'Not Assigned',
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
