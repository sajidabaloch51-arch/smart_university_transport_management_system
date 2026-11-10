import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/notice_card.dart';

/// Driver Notices tab — active notices for drivers (and "all").
class DriverNoticeScreen extends StatefulWidget {
  final int refreshToken;
  const DriverNoticeScreen({super.key, this.refreshToken = 0});

  @override
  State<DriverNoticeScreen> createState() => _DriverNoticeScreenState();
}

class _DriverNoticeScreenState extends State<DriverNoticeScreen> {
  Stream<List<NoticeModel>>? _stream;
  String? _boundUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind();
  }

  @override
  void didUpdateWidget(covariant DriverNoticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _stream = null;
      _boundUid = null;
      _bind();
    }
  }

  List<String> _resolveDriverIds() {
    final ids = <String>{};
    final dUid = context.read<DriverProvider>().driver?.uid;
    final aUid = context.read<AuthProvider>().uid;
    if (dUid != null && dUid.isNotEmpty) ids.add(dUid);
    if (aUid != null && aUid.isNotEmpty) ids.add(aUid);
    ids.add('driver_id');
    return ids.toList();
  }

  void _bind() {
    final ids = _resolveDriverIds();
    if (ids.isEmpty) return;
    final key = ids.join('|');
    if (_stream != null && _boundUid == key) return;
    _boundUid = key;
    _stream = context.read<NoticeProvider>().streamNoticesForDriver(
          ids.first,
          alternateDriverIds: ids.skip(1).toList(),
        );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final driver = context.watch<DriverProvider>().driver;
    if (_stream == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bind();
      });
    }
    if (driver == null) {
      return const Center(child: Text('Error loading notices'));
    }
    if (_stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AsyncStateView<List<NoticeModel>>(
      stream: _stream!,
      isEmpty: (notices) => notices.isEmpty,
      emptyMessage: 'No active notices.',
      timeout: const Duration(seconds: 12),
      onRetry: () {
        setState(() {
          _stream = null;
          _boundUid = null;
        });
        _bind();
      },
      builder: (context, notices) {
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
            Text(notice.message),
            const SizedBox(height: 12),
            Text(
              'Priority: ${notice.priority} • '
              '${DateFormat('dd MMM yyyy, hh:mm a').format(notice.createdAt.toLocal())}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}
