import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Color(0xFF003366)),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Nasir Ali',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'ID: DRV-UOG-005',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileItem(Icons.email, 'Email', 'nasir.ali@uog.edu.pk'),
                  _buildProfileItem(Icons.phone, 'Phone', '+92 300 1234567'),
                  _buildProfileItem(Icons.directions_bus, 'Assigned Bus', 'UOG-001'),
                  _buildProfileItem(Icons.route, 'Assigned Route', 'Route A'),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF003366)),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
