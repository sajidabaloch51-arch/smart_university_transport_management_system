import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageNoticesScreen extends StatelessWidget {
  const ManageNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notices')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          final types = ['general', 'delay', 'emergency'];
          final colors = [Colors.blue, Colors.orange, Colors.red];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: colors[index]),
              title: Text('Notice ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Type: ${types[index].toUpperCase()} | Target: All Users'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {}),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-notice'),
        icon: const Icon(Icons.add_alert),
        label: const Text('Post Notice'),
      ),
    );
  }
}
