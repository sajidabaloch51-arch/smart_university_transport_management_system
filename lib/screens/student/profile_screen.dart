import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StudentModel? _student;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final students = context.read<StudentProvider>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid') ?? auth.uid ?? '';
      if (uid.isEmpty) return;
      final student =
          await students.getStudent(uid).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _student = student);
    } catch (e) {
      debugPrint('ProfileScreen load failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _student?.name ?? 'Student',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Reg No: ${_student?.regNumber.isNotEmpty == true ? _student!.regNumber : '—'}',
                    style: const TextStyle(color: AppColors.grey),
                  ),
                  const SizedBox(height: 40),
                  _buildProfileItem(
                    Icons.school,
                    'Department',
                    _student?.department.isNotEmpty == true
                        ? _student!.department
                        : '—',
                  ),
                  _buildProfileItem(
                    Icons.account_balance,
                    'University',
                    'University of Gwadar',
                  ),
                  _buildProfileItem(
                    Icons.email,
                    'Email',
                    _student?.email.isNotEmpty == true
                        ? _student!.email
                        : '—',
                  ),
                  _buildProfileItem(
                    Icons.phone,
                    'Phone',
                    _student?.phone.isNotEmpty == true
                        ? _student!.phone
                        : '—',
                  ),
                  if (_student?.assignedRouteName != null)
                    _buildProfileItem(
                      Icons.route,
                      'Route',
                      _student!.assignedRouteName!,
                    ),
                  if (_student?.assignedBusCode != null)
                    _buildProfileItem(
                      Icons.directions_bus,
                      'Bus',
                      _student!.assignedBusCode!,
                    ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();
                        if (context.mounted) {
                          context.go('/role-selection');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('LOGOUT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
