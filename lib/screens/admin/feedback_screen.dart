import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Feedback'),
      ),
      body: const Center(
        child: Text(
          'No feedback submitted yet.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
