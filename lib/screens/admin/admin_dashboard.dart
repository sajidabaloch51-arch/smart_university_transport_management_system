import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(context, 'Manage Routes', Icons.alt_route),
          _buildCard(context, 'Manage Users', Icons.people),
          _buildCard(context, 'Manage Buses', Icons.directions_bus),
          _buildCard(context, 'Post Notice', Icons.notification_add),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
