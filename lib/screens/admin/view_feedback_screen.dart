import 'package:flutter/material.dart';

class ViewFeedbackScreen extends StatelessWidget {
  const ViewFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Feedback')),
      body: ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final feedbackItems = [
            {
              'student': 'Sajida Abdullah',
              'route': 'Route A',
              'rating': 5,
              'comment': 'The bus was right on time. Great service!',
              'date': 'Today'
            },
            {
              'student': 'Ali Khan',
              'route': 'Route B',
              'rating': 3,
              'comment': 'AC was not working properly today.',
              'date': 'Yesterday'
            },
            {
              'student': 'Sadia Abdul',
              'route': 'Route A',
              'rating': 4,
              'comment': 'Driver was very professional.',
              'date': '2 days ago'
            },
            {
              'student': 'Khadija Maqbool',
              'route': 'Route C',
              'rating': 2,
              'comment': 'Bus arrived 15 minutes late at the Fish Harbour stop.',
              'date': '3 days ago'
            },
          ];

          final item = feedbackItems[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['student'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(item['date'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['route'] as String,
                          style: const TextStyle(color: Color(0xFF003366), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < (item['rating'] as int) ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['comment'] as String,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
