import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/schedule_card.dart';
import '../../models/schedule_model.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schedules'),
      ),
      body: StreamBuilder<List<ScheduleModel>>(
        stream: scheduleProvider.streamSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var schedules = snapshot.data ?? [];

          if (schedules.isEmpty) {
            return const Center(child: Text('No schedules found for this period.'));
          }

          return ListView.builder(
            // Extra bottom padding so the FAB does not cover the last card.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return ScheduleCard(
                schedule: schedule,
                onEdit: () => context.push('/add-edit-schedule', extra: schedule),
                onDelete: () => _confirmDelete(context, scheduleProvider, schedule.id),
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

  void _confirmDelete(BuildContext context, ScheduleProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timing'),
        content: const Text('Are you sure you want to remove this timing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteSchedule(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timing deleted'), backgroundColor: Colors.red),
              );
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
