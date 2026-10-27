import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../models/schedule_model.dart';
import '../../utils/perf_log.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  late final Stream<List<ScheduleModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ScheduleProvider>().streamSchedules();
    PerfLog.start('screen_ManageSchedules');
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final initial = scheduleProvider.cachedSchedules.isEmpty
        ? null
        : scheduleProvider.cachedSchedules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
      ),
      body: CachedStreamList<List<ScheduleModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No schedules found for this period.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => scheduleProvider.refreshSchedules(),
        builder: (context, schedules) {
          PerfLog.end('screen_ManageSchedules',
              label: 'first_data', count: schedules.length);
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return ScheduleCard(
                schedule: schedule,
                onEdit: () =>
                    context.push('/add-edit-schedule', extra: schedule),
                onDelete: () =>
                    _confirmDelete(context, scheduleProvider, schedule.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-schedule'),
        icon: const Icon(Icons.more_time),
        label: const Text('Add Schedule'),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ScheduleProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timing'),
        content: const Text('Are you sure you want to remove this timing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSchedule(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Timing deleted'),
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
