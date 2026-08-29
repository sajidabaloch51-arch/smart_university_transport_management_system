import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/notice_model.dart';
import '../../widgets/notice_card.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<NoticeModel> notices = [
      NoticeModel(
        id: '1',
        title: "Bus Delay",
        description: "The departure from City Center will be delayed by 20 minutes due to unexpected road blocks.",
        date: DateTime.now(),
        type: NoticeType.delay,
        postedBy: 'Transport Admin',
      ),
      NoticeModel(
        id: '2',
        title: "Holiday Tomorrow",
        description: "All university transport services will be suspended tomorrow due to the public holiday announced by the government.",
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NoticeType.general,
        postedBy: 'Administration',
      ),
      NoticeModel(
        id: '3',
        title: "Route Closed",
        description: "Route C is closed until further notice due to emergency pipeline repairs on the main road.",
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: NoticeType.emergency,
        postedBy: 'Transport Dept',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Latest Notices')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          return NoticeCard(
            notice: notice,
            onReadMore: () => context.push('/notice-detail', extra: notice),
          );
        },
      ),
    );
  }
}
