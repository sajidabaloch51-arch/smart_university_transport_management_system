import 'package:flutter/material.dart';

class FeedbackCard extends StatelessWidget {
  final String studentName;
  final String route;
  final int rating;
  final String feedback;
  final String date;

  const FeedbackCard({
    super.key,
    required this.studentName,
    required this.route,
    required this.rating,
    required this.feedback,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(route, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < rating ? Icons.star : Icons.star_border, 
                      color: Colors.amber, 
                      size: 14
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(feedback, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
