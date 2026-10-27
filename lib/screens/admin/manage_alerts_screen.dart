import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../utils/perf_log.dart';

class ManageAlertsScreen extends StatefulWidget {
  const ManageAlertsScreen({super.key});

  @override
  State<ManageAlertsScreen> createState() => _ManageAlertsScreenState();
}

class _ManageAlertsScreenState extends State<ManageAlertsScreen> {
  final _alertService = AlertService();
  late final Stream<List<AlertModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _alertService.streamAllAlerts();
    PerfLog.start('screen_ManageAlerts');
  }

  Future<void> _toggle(AlertModel alert) async {
    try {
      await _alertService.setActive(alert.id, !alert.isActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(alert.isActive ? 'Alert deactivated' : 'Alert activated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(AlertModel alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Delete alert "${alert.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _alertService.deleteAlert(alert.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _alertService.cachedAlerts.isEmpty
        ? null
        : _alertService.cachedAlerts;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Alerts')),
      body: CachedStreamList<List<AlertModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No alerts yet.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => _alertService.refreshAllAlerts(),
        builder: (context, alerts) {
          PerfLog.end('screen_ManageAlerts',
              label: 'first_data', count: alerts.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return AlertCard(
                alert: alert,
                onEdit: () => context.push('/send-alert', extra: alert),
                onToggleActive: () => _toggle(alert),
                onDelete: () => _confirmDelete(alert),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/send-alert'),
        icon: const Icon(Icons.add_alert),
        label: const Text('Send Alert'),
      ),
    );
  }
}