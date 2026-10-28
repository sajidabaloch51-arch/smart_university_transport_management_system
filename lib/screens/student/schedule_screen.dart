import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule_model.dart';
import '../../widgets/list_skeleton.dart';

class ScheduleScreen extends StatefulWidget {
  final String? routeId;
  const ScheduleScreen({super.key, this.routeId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final Stream<List<ScheduleModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ScheduleProvider>().streamSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.read<ScheduleProvider>();
    final initial = scheduleProvider.cachedSchedules.isEmpty
        ? null
        : scheduleProvider.cachedSchedules;

    return Scaffold(
      appBar: AppBar(title: const Text('Transport Schedule')),
      body: CachedStreamList<List<ScheduleModel>>(
        stream: _stream,
        initialData: initial,
        emptyMessage: 'No schedules available.',
        isEmpty: (list) => list.isEmpty,
        onRefresh: () => scheduleProvider.refreshSchedules(),
        builder: (context, schedules) {
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              bool isMyRoute = false;
              final routeId = widget.routeId;
              if (routeId != null) {
                isMyRoute = schedule.routeName.contains(routeId) ||
                    routeId.contains(schedule.routeName);
              }

              return Column(
                children: [
                  if (isMyRoute)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Recommended for your route',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildScheduleCard(
                    schedule.routeName,
                    schedule.departureTime,
                    schedule.arrivalTime,
                    isMyRoute,
                    schedule.vehicleNo,
                    [schedule.shift],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(
    String title,
    String departure,
    String arrival,
    bool isMyRoute,
    String busNumber,
    List<String> days,
  ) {
    return Card(
      elevation: isMyRoute ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMyRoute
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isMyRoute ? AppColors.primary : AppColors.secondary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    busNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo('Departure', departure, Icons.launch),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                _buildTimeInfo('Arrival', arrival, Icons.login),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              children: days
                  .map(
                    (day) => Chip(
                      label: Text(day, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
