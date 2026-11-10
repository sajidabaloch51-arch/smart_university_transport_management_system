import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/notice_provider.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/notice_card.dart';

/// Standalone driver notices page — same notices stream as the Notices tab.
class DriverNoticesScreen extends StatefulWidget {
  const DriverNoticesScreen({super.key});

  @override
  State<DriverNoticesScreen> createState() => _DriverNoticesScreenState();
}

class _DriverNoticesScreenState extends State<DriverNoticesScreen> {
  Stream<List<NoticeModel>>? _stream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null) return;
    final ids = <String>{};
    final d = context.read<DriverProvider>().driver?.uid;
    final a = context.read<AuthProvider>().uid;
    if (d != null && d.isNotEmpty) ids.add(d);
    if (a != null && a.isNotEmpty) ids.add(a);
    ids.add('driver_id');
    final list = ids.toList();
    _stream = context.read<NoticeProvider>().streamNoticesForDriver(
          list.isEmpty ? '' : list.first,
          alternateDriverIds: list.skip(1).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Notices')),
      body: _stream == null
          ? const Center(child: CircularProgressIndicator())
          : AsyncStateView<List<NoticeModel>>(
              stream: _stream!,
              isEmpty: (n) => n.isEmpty,
              emptyMessage: 'No notices from admin yet.',
              timeout: const Duration(seconds: 12),
              onRetry: () => setState(() => _stream = null),
              builder: (context, notices) {
                return ListView.builder(
                  itemCount: notices.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return NoticeCard(
                      notice: notice,
                      onReadMore: () {},
                    );
                  },
                );
              },
            ),
    );
  }
}
