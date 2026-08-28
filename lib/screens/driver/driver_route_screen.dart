import 'package:flutter/material.dart';

class DriverRouteScreen extends StatelessWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Assigned Route')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF003366).withOpacity(0.05),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route A – Gwadar City Centre',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                ),
                SizedBox(height: 5),
                Text('Assigned Bus: UOG-001 | Shift: Morning (07:30 AM)', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please ensure you are at the first stop 10 minutes before departure.',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('ROUTE STOPS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                final stops = [
                  {'name': 'Gwadar Bus Stand', 'time': '07:30 AM'},
                  {'name': 'Fish Harbour', 'time': '07:45 AM'},
                  {'name': 'UoG Main Gate', 'time': '08:00 AM'},
                ];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF003366).withOpacity(0.1),
                    child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF003366))),
                  ),
                  title: Text(stops[index]['name']!),
                  subtitle: Text('Scheduled Departure: ${stops[index]['time']}'),
                  trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
