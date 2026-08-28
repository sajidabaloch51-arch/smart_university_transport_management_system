import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/notice_card.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latest Notices')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          NoticeCard(
            title: "Bus Delay",
            body: "The departure from City Center will be delayed by 20 minutes due to unexpected road blocks.",
            date: "Today",
            type: "delay",
            onTap: () => context.push('/notice-detail', extra: {
              'title': 'Bus Delay',
              'body': 'The departure from City Center will be delayed by 20 minutes due to unexpected road blocks.',
              'date': '20 April',
              'postedBy': 'Transport Admin'
            }),
          ),
          NoticeCard(
            title: "Holiday Tomorrow",
            body: "All university transport services will be suspended tomorrow due to the public holiday announced by the government.",
            date: "Yesterday",
            type: "general",
            onTap: () => context.push('/notice-detail', extra: {
              'title': 'Holiday Tomorrow',
              'body': 'All university transport services will be suspended tomorrow due to the public holiday announced by the government.',
              'date': '19 April',
              'postedBy': 'Administration'
            }),
          ),
          NoticeCard(
            title: "Route Closed",
            body: "Route C is closed until further notice due to emergency pipeline repairs on the main road.",
            date: "2 days ago",
            type: "emergency",
            onTap: () => context.push('/notice-detail', extra: {
              'title': 'Route Closed',
              'body': 'Route C is closed until further notice due to emergency pipeline repairs on the main road.',
              'date': '18 April',
              'postedBy': 'Transport Dept'
            }),
          ),
        ],
      ),
    );
  }
}
