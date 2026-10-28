import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _started = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    if (_started) return;
    _started = true;
    final uid = context.read<AuthProvider>().uid;
    if (uid == null || uid.isEmpty) {
      setState(() => _error = 'Not signed in');
      return;
    }
    try {
      await context
          .read<AdminProvider>()
          .fetchAdminData(uid)
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _error = null);
    } catch (e) {
      debugPrint('AdminProfile load failed: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        if (_error != null && provider.admin == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load profile.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        _started = false;
                        setState(() => _error = null);
                        _ensureLoaded();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (provider.isLoading || provider.admin == null) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final admin = provider.admin!;
        ImageProvider? imageProvider;
        if (admin.profilePhoto.isNotEmpty) {
          try {
            imageProvider = MemoryImage(base64Decode(admin.profilePhoto));
          } catch (_) {}
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
                        child: imageProvider == null
                            ? const Icon(Icons.person, size: 80)
                            : null,
                      ),
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.edit, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  admin.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(admin.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Employee ID'),
                  subtitle: Text(admin.employeeId),
                ),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Designation'),
                  subtitle: Text(
                    (admin.designation == null || admin.designation!.isEmpty)
                        ? '—'
                        : admin.designation!,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone'),
                  subtitle: Text(admin.phone),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Office'),
                  subtitle: Text(
                    (admin.officeLocation == null ||
                            admin.officeLocation!.isEmpty)
                        ? '—'
                        : admin.officeLocation!,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/role-selection');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
