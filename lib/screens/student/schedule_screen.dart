import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  final String routeId;
  const ScheduleScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Schedule - $routeId')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF003366).withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.arrow_upward, color: Color(0xFF003366)),
                    Text('To University', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                VerticalDivider(),
                Column(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.orange),
                    Text('From University', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Stop ${index + 1} Name'),
                  subtitle: const Text('Monday - Friday'),
                  trailing: Text(
                    '${07 + index}:30 AM',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
