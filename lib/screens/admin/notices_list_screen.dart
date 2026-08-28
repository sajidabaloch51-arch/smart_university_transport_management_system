import 'package:flutter/material.dart';

class NoticesListScreen extends StatelessWidget {
  const NoticesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notices')),
      body: ListView.builder(
        itemCount: 3,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final notices = [
            {
              'title': 'Bus Route A Delay',
              'body': 'Due to road construction, Route A will be delayed by 20 minutes.',
              'type': 'delay',
              'target': 'Students'
            },
            {
              'title': 'Emergency Meeting',
              'body': 'All drivers are requested to attend a meeting at 4 PM.',
              'type': 'emergency',
              'target': 'Drivers'
            },
            {
              'title': 'Holiday Notice',
              'body': 'Buses will not operate tomorrow due to a public holiday.',
              'type': 'general',
              'target': 'All'
            },
          ];

          Color typeColor = Colors.blue;
          if (notices[index]['type'] == 'emergency') typeColor = Colors.red;
          if (notices[index]['type'] == 'delay') typeColor = Colors.orange;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: typeColor),
              title: Text(notices[index]['title']!),
              subtitle: Text('Target: ${notices[index]['target']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle edit or delete
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              onTap: () {
                // View full notice
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Typically routes to post notice, which we already have
        },
        backgroundColor: const Color(0xFF003366),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
