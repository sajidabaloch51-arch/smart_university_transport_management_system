import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notice_model.dart';

class NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onReadMore;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;

  const NoticeCard({
    super.key,
    required this.notice,
    required this.onReadMore,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  });

  Color get _priorityColor {
    switch (notice.priority) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return const Color(0xFF1565C0);
    }
  }

  IconData get _priorityIcon {
    switch (notice.priority) {
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'important':
        return Icons.priority_high_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor;
    final faded = !notice.isActive || notice.isExpired;

    return Opacity(
      opacity: faded ? 0.65 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_priorityIcon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notice.priority.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    notice.audience.toUpperCase(),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM').format(notice.createdAt.toLocal()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notice.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                notice.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              if (notice.isExpired)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Expired',
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'By: ${notice.createdBy}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (onToggleActive != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notice.isActive ? 'Active' : 'Off',
                          style: TextStyle(
                            fontSize: 11,
                            color: notice.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        Switch.adaptive(
                          value: notice.isActive,
                          onChanged: onToggleActive,
                        ),
                      ],
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon:
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  TextButton(
                    onPressed: onReadMore,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                    child: const Text('Read More'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
