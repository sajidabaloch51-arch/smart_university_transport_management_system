import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';

class AddEditScheduleScreen extends StatefulWidget {
  const AddEditScheduleScreen({super.key});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  String? _selectedRoute;
  String? _selectedDriver;
  String? _selectedBus;
  
  TimeOfDay _departureTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 8, minute: 0);

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Timing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown('Select Route', ['Route A', 'Route B'], (v) => _selectedRoute = v),
            const SizedBox(height: 16),
            _buildDropdown('Select Driver', ['Nasir Ali', 'Ali Ahmed'], (v) => _selectedDriver = v),
            const SizedBox(height: 16),
            _buildDropdown('Select Bus', ['UOG-001', 'UOG-002'], (v) => _selectedBus = v),
            
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
            CustomButton(text: 'SAVE SCHEDULE', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
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
