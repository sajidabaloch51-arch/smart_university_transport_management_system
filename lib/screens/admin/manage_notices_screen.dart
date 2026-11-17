import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/notice_provider.dart';
import '../../utils/perf_log.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/notice_card.dart';

class ManageNoticesScreen extends StatefulWidget {
  const ManageNoticesScreen({super.key});

  @override
  State<ManageNoticesScreen> createState() => _ManageNoticesScreenState();
}

class _ManageNoticesScreenState extends State<ManageNoticesScreen> {
  late final Stream<List<NoticeModel>> _stream;
  bool _migrating = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NoticeProvider>();
    _stream = provider.streamNotices();
    PerfLog.start('screen_ManageNotices');
    // One-time backfill of legacy notice fields + copy alerts → notices.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMigrationQuietly());
  }

  Future<void> _runMigrationQuietly() async {
    if (_migrating) return;
    setState(() => _migrating = true);
    try {
      final result =
          await context.read<NoticeProvider>().migrateAlertsToNotices();
      if (!mounted) return;
      if (result.alertsCopied > 0 || result.noticesBackfilled > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notices updated: backfilled ${result.noticesBackfilled}, '
              'moved ${result.alertsCopied} old alert(s)'
              '${result.alertsSkipped > 0 ? ' (${result.alertsSkipped} skipped)' : ''}.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Notice migration skipped/failed: $e');
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  Future<void> _toggle(NoticeModel notice) async {
    try {
      await context.read<NoticeProvider>().setActive(notice.id, !notice.isActive);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(
    BuildContext context,
    NoticeProvider provider,
    NoticeModel notice,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice'),
        content: Text(
          'Are you sure you want to delete "${notice.title}" permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteNotice(notice.id);
              if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final noticeProvider = context.read<NoticeProvider>();
    final initial = noticeProvider.cachedNotices.isEmpty
        ? null
        : noticeProvider.cachedNotices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notices'),
        actions: [
          if (_migrating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Move old alerts to notices',
              onPressed: _runMigrationQuietly,
              icon: const Icon(Icons.sync),
            ),
        ],
      ),
      body: CachedStreamList<List<NoticeModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No notices found.',
        isEmpty: (list) => list.isEmpty,
        streamFactory: () {
          noticeProvider.restartNoticesStream();
          return noticeProvider.streamNotices();
        },
        onRefresh: () => noticeProvider.refreshNotices(),
        builder: (context, notices) {
          PerfLog.end(
            'screen_ManageNotices',
            label: 'first_data',
            count: notices.length,
          );
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return NoticeCard(
                notice: notice,
                onReadMore: () =>
                    context.push('/notice-detail', extra: notice),
                onEdit: () => context.push('/add-edit-notice', extra: notice),
                onDelete: () => _confirmDelete(context, noticeProvider, notice),
                onToggleActive: (_) => _toggle(notice),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-notice'),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Post Notice'),
      ),
    );
  }
}
