import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/alert_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/alert_service.dart';
import '../../widgets/alert_card.dart';

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

    return StreamBuilder<List<AlertModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          if (err is FirebaseException) {
            debugPrint(
              '🔥 DriverNoticeScreen error code=${err.code} message=${err.message}',
            );
          } else {
            debugPrint('🔥 DriverNoticeScreen error: $err');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    err is FirebaseException
                        ? 'Could not load alerts (${err.code}).'
                        : 'Could not load alerts.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _stream = null;
                        _boundUid = null;
                        _bind();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (_stream == null ||
            (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)) {
          return const Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No active transport alerts.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

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
