import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule_model.dart';
import '../../widgets/custom_button.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final ScheduleModel? schedule;
  const AddEditScheduleScreen({super.key, this.schedule});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRoute;
  String? _selectedDriver;
  String? _selectedBus;
  
  late TimeOfDay _departureTime;
  late TimeOfDay _arrivalTime;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late Set<String> _selectedDays;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.schedule?.routeName;
    _selectedBus = widget.schedule?.busNumber;
    
    _departureTime = const TimeOfDay(hour: 7, minute: 30);
    _arrivalTime = const TimeOfDay(hour: 8, minute: 0);
    _selectedDays = widget.schedule?.days.toSet() ?? {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
  }

  void _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final schedule = ScheduleModel(
        id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        busNumber: _selectedBus ?? 'Not Assigned',
        routeName: _selectedRoute ?? 'Not Assigned',
        departureTime: _departureTime.format(context),
        arrivalTime: _arrivalTime.format(context),
        days: _selectedDays.toList(),
      );

      try {
        await Provider.of<ScheduleProvider>(context, listen: false).addSchedule(schedule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Timing ${widget.schedule == null ? 'added' : 'updated'} successfully'), backgroundColor: Colors.green),
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
      appBar: AppBar(title: Text(widget.schedule == null ? 'Add Timing' : 'Edit Timing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown('Select Route', ['Route A', 'Route B'], (v) => setState(() => _selectedRoute = v)),
              const SizedBox(height: 16),
              _buildDropdown('Select Driver', ['Nasir Ali', 'Ali Ahmed'], (v) => setState(() => _selectedDriver = v)),
              const SizedBox(height: 16),
              _buildDropdown('Select Bus', ['UOG-001', 'UOG-002'], (v) => setState(() => _selectedBus = v)),
              
              const Divider(height: 40),
              
              const Text('Operational Days', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _days.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedDays.add(day);
                        else _selectedDays.remove(day);
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 30),
              
              Row(
                children: [
                  Expanded(child: _buildTimePicker('Departure', _departureTime, (t) => setState(() => _departureTime = t))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker('Arrival', _arrivalTime, (t) => setState(() => _arrivalTime = t))),
                ],
              ),
              
              const SizedBox(height: 50),
              CustomButton(
                text: widget.schedule == null ? 'SAVE SCHEDULE' : 'UPDATE SCHEDULE', 
                isLoading: _isLoading,
                onPressed: _saveSchedule,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    String? currentValue;
    if (label == 'Select Route') currentValue = _selectedRoute;
    else if (label == 'Select Bus') currentValue = _selectedBus;
    else if (label == 'Select Driver') currentValue = _selectedDriver;

    return DropdownButtonFormField<String>(
      value: items.contains(currentValue) ? currentValue : null,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onPicked(t);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(time.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
