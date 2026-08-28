import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageScheduleScreen extends StatelessWidget {
  const ManageScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Schedules')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          final routes = ['Route A', 'Route B', 'Route C'];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(routes[index], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Monday - Friday'),
              children: [
                _buildScheduleRow('Morning Shift', '07:30 AM', 'To University'),
                _buildScheduleRow('Evening Shift', '02:30 PM', 'From University'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () => context.push('/add-schedule'), 
                    icon: const Icon(Icons.add_circle_outline), 
                    label: const Text('Add Timing')
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-schedule'),
        child: const Icon(Icons.schedule),
      ),
    );
  }

  Widget _buildScheduleRow(String shift, String time, String direction) {
    return ListTile(
      dense: true,
      title: Text(shift, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$direction • Starts at $time'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
          IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () {}),
        ],
      ),
    );
  }
}
