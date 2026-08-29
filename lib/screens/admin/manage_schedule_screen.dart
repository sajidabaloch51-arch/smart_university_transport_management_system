import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/schedule_card.dart';
import '../../models/schedule_model.dart';

class ManageScheduleScreen extends StatelessWidget {
  const ManageScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Schedules')),
      body: StreamBuilder<List<ScheduleModel>>(
        stream: scheduleProvider.streamSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final schedules = snapshot.data ?? [];
          if (schedules.isEmpty) {
            return const Center(child: Text('No schedules found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              return ScheduleCard(
                schedule: schedules[index],
                onEdit: () => context.push('/add-edit-schedule', extra: schedules[index]),
                onDelete: () {},
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-schedule'),
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
    );
  }
}
