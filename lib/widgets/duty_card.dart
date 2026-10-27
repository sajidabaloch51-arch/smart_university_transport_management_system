import 'package:flutter/material.dart';
import '../models/duty_model.dart';
import '../utils/karachi_time.dart';

class DutyCard extends StatelessWidget {
  final DutyModel duty;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const DutyCard({
    super.key,
    required this.duty,
    this.onEdit,
    this.onCancel,
    this.onComplete,
    this.onDelete,
  });

  Color get _statusColor {
    switch (duty.status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeRange =
        '${KarachiTime.formatTime(duty.shiftStart)} – ${KarachiTime.formatTime(duty.shiftEnd)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    duty.route.isEmpty ? 'Unnamed route' : duty.route,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    duty.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bus No: ${duty.busNo.isEmpty ? '—' : duty.busNo}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timeRange,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${duty.dutyDate}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (duty.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                duty.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
            if (onEdit != null ||
                onCancel != null ||
                onComplete != null ||
                onDelete != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                    ),
                  if (onComplete != null &&
                      duty.status != 'completed' &&
                      duty.status != 'cancelled')
                    IconButton(
                      tooltip: 'Mark completed',
                      icon: const Icon(Icons.check_circle_outline,
                          size: 18, color: Colors.green),
                      visualDensity: VisualDensity.compact,
                      onPressed: onComplete,
                    ),
                  if (onCancel != null &&
                      duty.status != 'cancelled' &&
                      duty.status != 'completed')
                    IconButton(
                      tooltip: 'Cancel',
                      icon: const Icon(Icons.cancel_outlined,
                          size: 18, color: Colors.orange),
                      visualDensity: VisualDensity.compact,
                      onPressed: onCancel,
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
