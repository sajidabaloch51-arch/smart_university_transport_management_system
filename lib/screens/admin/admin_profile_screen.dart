import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
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
                    child: Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF003366)),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Sajida Abdullah',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'System Administrator',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileItem(Icons.email, 'Email', 'admin@uog.edu.pk'),
                  _buildProfileItem(Icons.phone, 'Support Phone', '+92 300 0000000'),
                  _buildProfileItem(Icons.school, 'University', 'University of Gwadar'),
                  _buildProfileItem(Icons.security, 'Access Level', 'Super Admin'),
                  const SizedBox(height: 30),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('System Settings'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  const ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Help & Documentation'),
                    trailing: Icon(Icons.chevron_right),
                  ),
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
