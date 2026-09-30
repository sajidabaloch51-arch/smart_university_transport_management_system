import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/notice_card.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latest Notices')),
      body: Consumer<NoticeProvider>(
        builder: (context, noticeProvider, child) {
          final notices = noticeProvider.noticesForRole('student');

          if (notices.isEmpty) {
            return const Center(
              child: Text('No notices from admin yet.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final NoticeModel notice = notices[index];
              return NoticeCard(
                notice: notice,
                onReadMore: () => context.push('/notice-detail', extra: notice),
              );
            },
          );
        },
      ),
    );
  }
}
