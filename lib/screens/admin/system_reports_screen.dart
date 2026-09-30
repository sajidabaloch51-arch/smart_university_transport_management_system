import 'package:flutter/material.dart';

class SystemReportsScreen extends StatelessWidget {
  const SystemReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Reports')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Transport Reports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select a report category to download data in PDF or CSV format.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildReportOption(
              context, 
              title: 'Student Ridership Report',
              subtitle: 'Daily/Weekly student transport usage data.',
              icon: Icons.group,
              color: Colors.blue,
            ),
            _buildReportOption(
              context, 
              title: 'Driver Performance Report',
              subtitle: 'Trip counts and punctuality statistics.',
              icon: Icons.speed,
              color: Colors.green,
            ),
            _buildReportOption(
              context, 
              title: 'Fleet Maintenance Report',
              subtitle: 'Bus condition and service history.',
              icon: Icons.build,
              color: Colors.orange,
            ),
            _buildReportOption(
              context, 
              title: 'Financial Summary',
              subtitle: 'Fuel expenses and maintenance costs.',
              icon: Icons.payments,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.download_rounded),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generating $title...')),
          );
        },
      ),
    );
  }
}
