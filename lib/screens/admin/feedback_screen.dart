import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Feedback')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          final ratings = [5, 4, 3, 2];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sajida Abdullah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Today', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Route A', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(starIndex < ratings[index] ? Icons.star : Icons.star_border, color: Colors.amber, size: 14);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('The bus driver was very helpful and the commute was on time. Thank you!', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
