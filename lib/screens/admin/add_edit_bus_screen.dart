import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bus_model.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditBusScreen extends StatefulWidget {
  final BusModel? bus; // kept for edit identity + preserving other fields
  const AddEditBusScreen({super.key, this.bus});

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNoController;
  late TextEditingController _regNoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _busNoController =
        TextEditingController(text: widget.bus?.busNumber ?? '');
    _regNoController =
        TextEditingController(text: widget.bus?.registrationNumber ?? '');
  }

  @override
  void dispose() {
    _busNoController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final busId = widget.bus?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final existing = widget.bus;

    // Form fields only — never clear assignments set by Edit Driver.
    final fields = <String, dynamic>{
      'busNumber': _busNoController.text.trim(),
    };
    final reg = _regNoController.text.trim();
    if (reg.isNotEmpty) {
      fields['registrationNumber'] = reg;
    }
    if (existing == null) {
      fields['isActive'] = true;
    }

    try {
      await context.read<BusProvider>().saveBusFields(busId, fields);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bus ${widget.bus == null ? 'registered' : 'updated'} successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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
