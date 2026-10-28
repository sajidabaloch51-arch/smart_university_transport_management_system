import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../core/validators/app_validators.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/email_validator.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _firestoreService = FirestoreService();

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameController, 
                    labelText: 'Full Name',
                    prefixIcon: Icons.person,
                    validator: AppValidators.validateFullName,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: emailController, 
                    labelText: 'Email',
                    hintText: AppEmailValidator.hint,
                    helperText: AppEmailValidator.hint,
                    prefixIcon: Icons.email,
                    validator: AppValidators.validateEmail,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: passwordController, 
                    labelText: 'Password', 
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    validator: AppValidators.validatePassword,
                    maxLength: 20,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'driver', child: Text('Driver')),
                    ],
                    onChanged: (v) => setDialogState(() => role = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final user = UserModel(
                    uid: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    email: AppEmailValidator.normalize(emailController.text),
                    phone: '',
                    role: role,
                  );
                  await _firestoreService.createUser(user);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Students'), Tab(text: 'Drivers')],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            UserList(role: 'student', firestore: _firestoreService),
            UserList(role: 'driver', firestore: _firestoreService),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddUserDialog,
          backgroundColor: const Color(0xFF003366),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final String role;
  final FirestoreService firestore;
  const UserList({super.key, required this.role, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: firestore.getUsers(role),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load users.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No ${role}s found.'));
        }

        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
