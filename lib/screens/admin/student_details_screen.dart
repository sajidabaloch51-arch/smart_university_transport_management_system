import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../core/constants/app_colors.dart';

class StudentDetailsScreen extends StatelessWidget {
  final StudentModel student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: student.profileImage.isNotEmpty
                        ? ClipOval(child: Image.network(student.profileImage, fit: BoxFit.cover, width: 120, height: 120))
                        : const Icon(Icons.person, size: 80, color: AppColors.primary),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: student.isActive ? Colors.green : Colors.red,
                    child: Icon(
                      student.isActive ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              student.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              student.regNumber,
              style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            _buildInfoSection('Academic Information', [
              _infoTile(Icons.school_outlined, 'Department', student.department),
              _infoTile(Icons.calendar_view_day_outlined, 'Semester', student.semester),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Contact Information', [
              _infoTile(Icons.email_outlined, 'Email', student.email),
              _infoTile(Icons.phone_outlined, 'Phone', student.phone),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Personal Details', [
              _infoTile(Icons.person_outline, 'Father\'s Name', student.fatherName),
              _infoTile(Icons.wc_outlined, 'Gender', student.gender),
              _infoTile(Icons.cake_outlined, 'Date of Birth', student.dob),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Transport Details', [
              _infoTile(Icons.map_outlined, 'Route Address', student.routeAddress),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        value.isEmpty ? 'Not Provided' : value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
