import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Drivers'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [
            UserList(role: 'student'),
            UserList(role: 'driver'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context),
          backgroundColor: const Color(0xFF003366),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    // This will be implemented to add students/drivers
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Full Name')),
            TextField(decoration: InputDecoration(labelText: 'Email')),
            TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            // Role selection dropdown would go here
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create')),
        ],
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final String role;
  const UserList({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Mock data for now
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('$role ${index + 1}'),
          subtitle: Text('$role${index + 1}@uog.edu.pk'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        );
      },
    );
  }
}
