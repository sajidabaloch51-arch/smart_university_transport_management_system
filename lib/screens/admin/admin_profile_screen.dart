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
            const SizedBox(height: 32),
            const Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(radius: 60, child: Icon(Icons.person, size: 80)),
                  CircleAvatar(radius: 18, child: Icon(Icons.edit, size: 16)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sajida Abdullah', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('System Administrator', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _profileTile(Icons.email, 'Email Address', 'admin@uog.edu.pk'),
            _profileTile(Icons.phone, 'Support Phone', '+92 300 1234567'),
            _profileTile(Icons.school, 'Institution', 'University of Gwadar'),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text('CHANGE PASSWORD')),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'), 
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('LOGOUT ACCOUNT')
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.blue, size: 20)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
