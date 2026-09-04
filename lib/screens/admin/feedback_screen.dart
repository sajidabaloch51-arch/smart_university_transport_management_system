import 'package:flutter/material.dart';
import '../../widgets/feedback_card.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Feedback'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          final items = [
            {'name': 'Sajida Abdullah', 'route': 'Route A', 'rating': 5, 'text': 'Excellent service, bus was on time.', 'date': 'Today'},
            {'name': 'Sadia Abdul', 'route': 'Route B', 'rating': 4, 'text': 'Driver was very polite. AC was working well.', 'date': 'Yesterday'},
            {'name': 'Khadija Maqbool', 'route': 'Route A', 'rating': 3, 'text': 'Bus arrived 10 minutes late at City Center stop.', 'date': '2 days ago'},
            {'name': 'Nasir Ali', 'route': 'Route C', 'rating': 5, 'text': 'Great tracking feature, very helpful.', 'date': '3 days ago'},
            {'name': 'Ali Ahmed', 'route': 'Route B', 'rating': 4, 'text': 'Overall good experience.', 'date': '4 days ago'},
          ];
          final item = items[index];
          return FeedbackCard(
            studentName: item['name'] as String,
            route: item['route'] as String,
            rating: item['rating'] as int,
            feedback: item['text'] as String,
            date: item['date'] as String,
          );
        },
      ),
    );
  }
}
