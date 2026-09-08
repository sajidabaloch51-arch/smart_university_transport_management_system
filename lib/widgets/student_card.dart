import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/student_model.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentCard({
    super.key,
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget profileImage;
    if (student.profileImage.isEmpty) {
      profileImage = const Icon(Icons.person);
    } else if (student.profileImage.startsWith('http')) {
      profileImage = ClipOval(child: Image.network(student.profileImage, fit: BoxFit.cover, width: 50, height: 50));
    } else {
      try {
        profileImage = ClipOval(child: Image.memory(base64Decode(student.profileImage), fit: BoxFit.cover, width: 50, height: 50));
      } catch (e) {
        profileImage = const Icon(Icons.person);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue.shade100,
          child: profileImage,
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${student.regNumber} | ${student.department}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: student.isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    student.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: student.isActive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'view') onView();
            if (val == 'edit') onEdit();
            if (val == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
