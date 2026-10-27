import 'package:flutter/material.dart';

import '../constants/feedback_categories.dart';
import '../models/feedback_model.dart';
import '../utils/karachi_time.dart';

/// Compact feedback card (list preview). Name/roll hidden by default.
class FeedbackCard extends StatelessWidget {
  final FeedbackModel item;
  final VoidCallback? onTap;

  const FeedbackCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = FeedbackCategories.colorFor(item.category);
    final statusColor = FeedbackStatuses.colorFor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FeedbackCategories.iconFor(item.category),
                    size: 16,
                    color: catColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                  ),
                  Text(
                    FeedbackStatuses.label(item.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.message, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                KarachiTime.formatDateTime(item.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
