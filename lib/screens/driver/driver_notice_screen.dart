import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/alert_service.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/async_state_view.dart';

/// Driver Notices tab — live alerts from Admin (`alerts` collection).
class DriverNoticeScreen extends StatefulWidget {
  final int refreshToken;
  const DriverNoticeScreen({super.key, this.refreshToken = 0});

  @override
  State<DriverNoticeScreen> createState() => _DriverNoticeScreenState();
}

class _DriverNoticeScreenState extends State<DriverNoticeScreen> {
  final _alertService = AlertService();
  Stream<List<AlertModel>>? _stream;
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

  void _bind() {
    final ids = <String>{};
    final dUid = context.read<DriverProvider>().driver?.uid;
    final aUid = context.read<AuthProvider>().uid;
    if (dUid != null && dUid.isNotEmpty) ids.add(dUid);
    if (aUid != null && aUid.isNotEmpty) ids.add(aUid);
    ids.add('driver_id');
    if (ids.isEmpty) {
      debugPrint('DriverNoticeScreen waiting for uid…');
      return;
    }
    final key = ids.join('|');
    if (_stream != null && _boundUid == key) return;
    _boundUid = key;
    final primary = ids.first;
    debugPrint('DriverNoticeScreen binding stream ids=$ids');
    // No Stream.timeout — live snapshots stay quiet between updates.
    _stream = _alertService.streamDriverAlerts(
      primary,
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
      return const Center(child: Text('Error loading alerts'));
    }

    if (_stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AsyncStateView<List<AlertModel>>(
      stream: _stream!,
      isEmpty: (alerts) => alerts.isEmpty,
      emptyMessage: 'No active transport alerts.',
      timeout: const Duration(seconds: 12),
      onRetry: () {
        setState(() {
          _stream = null;
          _boundUid = null;
        });
        _bind();
      },
      builder: (context, alerts) {
        // Keep builder body below — former StreamBuilder success path.

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return AlertCard(
              alert: alert,
              onTap: () => _showDetails(context, alert),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, AlertModel alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(alert.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 12),
            Text(
              'Severity: ${alert.severity} • ${DateFormat('dd MMM yyyy, hh:mm a').format(alert.createdAt.toLocal())}',
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
