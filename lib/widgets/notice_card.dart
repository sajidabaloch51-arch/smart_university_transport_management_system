import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class NoticeCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String type;
  final VoidCallback onTap;

  const NoticeCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = AppTheme.primaryColor;
    if (type.toLowerCase() == 'emergency') typeColor = AppTheme.errorColor;
    if (type.toLowerCase() == 'delay') typeColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications, color: typeColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
