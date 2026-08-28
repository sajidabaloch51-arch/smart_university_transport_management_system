import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoticeDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final DateTime date;

  const NoticeDetailScreen({
    super.key,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor = Colors.blue;
    if (type == 'emergency') typeColor = Colors.red;
    if (type == 'delay') typeColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Notice Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                type.toUpperCase(),
                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              DateFormat('MMMM dd, yyyy • hh:mm a').format(date),
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 40),
            Text(
              body,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 50),
            if (type == 'emergency')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'This is an emergency alert. Please follow instructions carefully.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
