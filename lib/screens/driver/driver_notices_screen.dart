import 'package:flutter/material.dart';

class DriverNoticesScreen extends StatelessWidget {
  const DriverNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Notices')),
      body: ListView.builder(
        itemCount: 3,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final notices = [
            {
              'title': 'Emergency Road Closure',
              'body': 'Main road towards City Centre is closed. Please use the bypass route.',
              'type': 'emergency',
              'date': 'Today'
            },
            {
              'title': 'New Fuel Cards',
              'body': 'Please collect your updated fuel cards from the admin office.',
              'type': 'general',
              'date': 'Yesterday'
            },
            {
              'title': 'Maintenance Check',
              'body': 'Bus UOG-001 is scheduled for maintenance this Saturday.',
              'type': 'delay',
              'date': '2 days ago'
            },
          ];
          
          Color typeColor = Colors.blue;
          if (notices[index]['type'] == 'emergency') typeColor = Colors.red;
          if (notices[index]['type'] == 'delay') typeColor = Colors.orange;

          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          notices[index]['type']!.toUpperCase(),
                          style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      Text(notices[index]['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notices[index]['title']!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notices[index]['body']!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
