import 'package:flutter/material.dart';

class ManageBusesScreen extends StatelessWidget {
  const ManageBusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Buses')),
      body: ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.directions_bus, size: 40, color: Color(0xFF003366)),
              title: Text('Bus UOG-00${index + 1}'),
              subtitle: Text('Capacity: 40 | Route: Route ${String.fromCharCode(65 + index)}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBusDialog(context),
        backgroundColor: const Color(0xFF003366),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddBusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Bus'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Bus Number (e.g., UOG-101)')),
            TextField(decoration: InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
            // Route dropdown would go here
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Add')),
        ],
      ),
    );
  }
}
