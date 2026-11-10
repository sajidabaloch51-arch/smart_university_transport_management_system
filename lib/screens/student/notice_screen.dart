import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/notice_card.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  late final Stream<List<NoticeModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<NoticeProvider>().streamNoticesForStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latest Notices')),
      body: AsyncStateView<List<NoticeModel>>(
        stream: _stream,
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'No notices from admin yet.',
        timeout: const Duration(seconds: 12),
        onRetry: () => setState(() {}),
        builder: (context, notices) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return NoticeCard(
                notice: notice,
                onReadMore: () =>
                    context.push('/notice-detail', extra: notice),
              );
            },
          );
        },
      ),
    );
  }
}
