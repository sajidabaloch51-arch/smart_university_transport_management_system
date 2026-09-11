import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import 'dart:convert';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        final admin = provider.admin;
        if (admin == null) return const Center(child: CircularProgressIndicator());

        ImageProvider? imageProvider;
        if (admin.profilePhoto.isNotEmpty) {
          try {
            imageProvider = MemoryImage(base64Decode(admin.profilePhoto));
          } catch (e) {}
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Admin Profile')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60, 
                        backgroundImage: imageProvider,
                        child: imageProvider == null ? const Icon(Icons.person, size: 80) : null
                      ),
                      const CircleAvatar(radius: 18, child: Icon(Icons.edit, size: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(admin.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(admin.designation, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                _profileTile(Icons.email, 'Official Email', admin.email),
                _profileTile(Icons.badge, 'Employee ID', admin.employeeId),
                _profileTile(Icons.location_city, 'Office Location', admin.officeLocation),
                _profileTile(Icons.phone, 'Support Phone', admin.phone),
                _profileTile(Icons.school, 'Institution', admin.university),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      OutlinedButton(onPressed: () {}, child: const Text('CHANGE PASSWORD')),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.logout();
                          if (context.mounted) {
                            context.go('/role-selection');
                          }
                        }, 
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
      },
    );
  }

  Widget _profileTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), 
        child: Icon(icon, color: Colors.blue, size: 20)
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
