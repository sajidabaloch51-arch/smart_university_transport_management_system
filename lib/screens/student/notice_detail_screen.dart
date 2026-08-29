import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/notice_model.dart';
import 'package:intl/intl.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({
    super.key,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = AppColors.primary;
    if (notice.type == NoticeType.emergency) typeColor = AppColors.error;
    if (notice.type == NoticeType.delay) typeColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Notice Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                notice.type.name.toUpperCase(),
                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            const SizedBox(height: 12),
            Text(notice.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaData(Icons.calendar_today, DateFormat('dd MMM yyyy').format(notice.date)),
                _buildMetaData(Icons.person, notice.postedBy),
              ],
            ),
            const Divider(height: 40),
            Text(
              notice.description,
              style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaData(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
      ],
    );
  }
}
