import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/notice_card.dart';

/// Driver notices tab — shows notices posted by admin for drivers / all users.
class DriverNoticeScreen extends StatelessWidget {
  const DriverNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoticeProvider>(
      builder: (context, noticeProvider, child) {
        final notices = noticeProvider.noticesForRole('driver');

        if (notices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notices from admin yet.', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  'When admin posts a notice for drivers,\nit will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return NoticeCard(
              notice: notice,
              onReadMore: () => _showDetails(context, notice),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(notice.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.description),
            const SizedBox(height: 12),
            Text(
              'Posted by ${notice.postedBy} • ${DateFormat('dd MMM yyyy, hh:mm a').format(notice.date)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT')),
        ],
      ),
    );
  }
}
