import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notice_model.dart';

class NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onReadMore;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoticeCard({
    super.key, 
    required this.notice, 
    required this.onReadMore,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.blue;
    IconData statusIcon = Icons.info_outline;

    if (notice.type == NoticeType.emergency) {
      statusColor = Colors.red;
      statusIcon = Icons.warning_amber_rounded;
    } else if (notice.type == NoticeType.delay) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  notice.type.name.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM').format(notice.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notice.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              notice.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('By: ${notice.postedBy}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                Row(
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue), 
                        onPressed: onEdit
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red), 
                        onPressed: onDelete
                      ),
                    TextButton(
                      onPressed: onReadMore,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      child: const Text('Read More'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
