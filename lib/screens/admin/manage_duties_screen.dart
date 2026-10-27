import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/duty_model.dart';
import '../../services/duty_service.dart';
import '../../widgets/duty_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../utils/perf_log.dart';

class ManageDutiesScreen extends StatefulWidget {
  const ManageDutiesScreen({super.key});

  @override
  State<ManageDutiesScreen> createState() => _ManageDutiesScreenState();
}

class _ManageDutiesScreenState extends State<ManageDutiesScreen> {
  final _dutyService = DutyService();
  late final Stream<List<DutyModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = _dutyService.streamAllDuties();
    PerfLog.start('screen_ManageDuties');
  }

  Future<void> _setStatus(DutyModel duty, String status) async {
    try {
      await _dutyService.updateStatus(duty.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duty marked $status'),
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

  void _confirmDelete(DutyModel duty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Duty'),
        content: Text('Delete duty for ${duty.driverName} on ${duty.dutyDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _dutyService.deleteDuty(duty.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Duty deleted'),
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
    final initial = _dutyService.cachedDuties.isEmpty
        ? null
        : _dutyService.cachedDuties;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Duties')),
      body: CachedStreamList<List<DutyModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No duties assigned yet.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => _dutyService.refreshAllDuties(),
        builder: (context, duties) {
          PerfLog.end('screen_ManageDuties',
              label: 'first_data', count: duties.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: duties.length,
            itemBuilder: (context, index) {
              final duty = duties[index];
              return DutyCard(
                duty: duty,
                onEdit: () => context.push('/assign-duty', extra: duty),
                onComplete: () => _setStatus(duty, 'completed'),
                onCancel: () => _setStatus(duty, 'cancelled'),
                onDelete: () => _confirmDelete(duty),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/assign-duty'),
        icon: const Icon(Icons.assignment_ind_outlined),
        label: const Text('Assign Duty'),
      ),
    );
  }
}
