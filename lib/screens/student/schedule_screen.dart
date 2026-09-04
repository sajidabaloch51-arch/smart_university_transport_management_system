import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ScheduleScreen extends StatelessWidget {
  final String routeId;
  const ScheduleScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Route $routeId Schedule')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildScheduleCard('Morning Shift', '07:30 AM', '08:00 AM', true),
          const SizedBox(height: 16),
          _buildScheduleCard('Afternoon Shift', '01:30 PM', '02:00 PM', false),
          const SizedBox(height: 32),
          const Text(
            'Weekly Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day) {
              return Chip(
                label: Text(day),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide.none,
                labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String title, String departure, String arrival, bool isPrimary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPrimary ? AppColors.primary : AppColors.secondary,
              ),
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
            Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
        ),
        Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
