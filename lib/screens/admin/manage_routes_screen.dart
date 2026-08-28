import 'package:flutter/material.dart';

class ManageRoutesScreen extends StatelessWidget {
  const ManageRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Routes')),
      body: ListView.builder(
        itemCount: 3, // Mock data count
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text('Route ${String.fromCharCode(65 + index)}'),
              subtitle: const Text('City Centre ↔ University'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF003366),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
