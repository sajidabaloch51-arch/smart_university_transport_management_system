import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/notice_card.dart';
import '../../models/notice_model.dart';

class ManageNoticesScreen extends StatelessWidget {
  const ManageNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final noticeProvider = Provider.of<NoticeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notices')),
      body: StreamBuilder<List<NoticeModel>>(
        stream: noticeProvider.streamNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return const Center(child: Text('No notices found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return NoticeCard(
                notice: notice,
                onReadMore: () {},
                onEdit: () => context.push('/add-edit-notice', extra: notice),
                onDelete: () => _confirmDelete(context, noticeProvider, notice.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-notice'),
        icon: const Icon(Icons.add_alert),
        label: const Text('Post Notice'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, NoticeProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteNotice(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notice deleted'), backgroundColor: Colors.red),
              );
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
