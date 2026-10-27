import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
    this.onDelete,
  });

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return const Color(0xFF1565C0);
    }
  }

  IconData get _severityIcon {
    switch (alert.severity) {
      case 'critical':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = _severityColor;
    final faded = !alert.isActive || alert.isExpired;

    return Opacity(
      opacity: faded ? 0.65 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: border.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_severityIcon, color: border, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: border,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: border.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                          color: border,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  '${alert.target == 'all_drivers' ? 'All drivers' : 'Specific driver'}'
                  ' • ${DateFormat('dd MMM yyyy, hh:mm a').format(alert.createdAt.toLocal())}'
                  '${alert.isActive ? '' : ' • Inactive'}'
                  '${alert.isExpired ? ' • Expired' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                if (onEdit != null ||
                    onToggleActive != null ||
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
                      if (onToggleActive != null)
                        IconButton(
                          tooltip: alert.isActive ? 'Deactivate' : 'Activate',
                          icon: Icon(
                            alert.isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off_outlined,
                            size: 28,
                            color: alert.isActive ? Colors.green : Colors.grey,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: onToggleActive,
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
