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

  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _busNoController = TextEditingController(text: widget.bus?.busNumber ?? '');
    _regNoController =
        TextEditingController(text: widget.bus?.registrationNumber ?? '');
    _isActive = widget.bus?.isActive ?? true;
  }

  @override
  void dispose() {
    _busNoController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  void _saveBus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Only store real values — no empty IDs / "Not Assigned" / null clutter.
    final bus = BusModel(
      id: widget.bus?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      busNumber: _busNoController.text.trim(),
      registrationNumber: _regNoController.text.trim(),
      assignedDriverId: widget.bus?.assignedDriverId ?? '',
      assignedDriverName: widget.bus?.assignedDriverName ?? '',
      assignedRouteId: widget.bus?.assignedRouteId ?? '',
      assignedRouteName: widget.bus?.assignedRouteName ?? '',
      isActive: _isActive,
    );

    try {
      await Provider.of<BusProvider>(context, listen: false).addBus(bus);
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
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
                labelText: 'Registration Number (optional)',
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
