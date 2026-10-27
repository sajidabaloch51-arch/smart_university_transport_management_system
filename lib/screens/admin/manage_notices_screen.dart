import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../models/notice_model.dart';
import '../../utils/perf_log.dart';

class ManageNoticesScreen extends StatefulWidget {
  const ManageNoticesScreen({super.key});

  @override
  State<ManageNoticesScreen> createState() => _ManageNoticesScreenState();
}

class _ManageNoticesScreenState extends State<ManageNoticesScreen> {
  late final Stream<List<NoticeModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<NoticeProvider>().streamNotices();
    PerfLog.start('screen_ManageNotices');
  }

  @override
  Widget build(BuildContext context) {
    final noticeProvider = context.read<NoticeProvider>();
    final initial = noticeProvider.cachedNotices.isEmpty
        ? null
        : noticeProvider.cachedNotices;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notices')),
      body: CachedStreamList<List<NoticeModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No notices found.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => noticeProvider.refreshNotices(),
        builder: (context, notices) {
          PerfLog.end('screen_ManageNotices',
              label: 'first_data', count: notices.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return NoticeCard(
                notice: notice,
                onReadMore: () {},
                onEdit: () => context.push('/add-edit-notice', extra: notice),
                onDelete: () =>
                    _confirmDelete(context, noticeProvider, notice.id),
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

  void _confirmDelete(
    BuildContext context,
    NoticeProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text(
          'Are you sure you want to delete this notice permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteNotice(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notice deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
