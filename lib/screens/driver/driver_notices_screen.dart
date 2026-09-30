import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/notice_provider.dart';

/// Standalone driver notices page — same data source as admin NoticeProvider.
class DriverNoticesScreen extends StatelessWidget {
  const DriverNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Notices')),
      body: Consumer<NoticeProvider>(
        builder: (context, noticeProvider, child) {
          final notices = noticeProvider.noticesForRole('driver');

          if (notices.isEmpty) {
            return const Center(
              child: Text('No notices from admin yet.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: notices.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final notice = notices[index];
              Color typeColor = Colors.blue;
              if (notice.type == NoticeType.emergency) typeColor = Colors.red;
              if (notice.type == NoticeType.delay) typeColor = Colors.orange;

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              notice.type.name.toUpperCase(),
                              style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM').format(notice.date),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(notice.description, style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(
                        'From: ${notice.postedBy}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
