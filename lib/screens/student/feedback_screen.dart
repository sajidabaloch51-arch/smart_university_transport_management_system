import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _firestoreService = FirestoreService();
  final _commentController = TextEditingController();
  double _rating = 5;
  String? _selectedRoute;

  void _submitFeedback() async {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route')),
      );
      return;
    }

    await _firestoreService.addFeedback({
      'universityId': 'uog',
      'submittedBy': 'student_123',
      'routeId': _selectedRoute,
      'rating': _rating,
      'comment': _commentController.text,
      'createdAt': DateTime.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate your experience:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Route', border: OutlineInputBorder()),
              items: ['Route A', 'Route B', 'Route C'].map((r) {
                return DropdownMenuItem(value: r, child: Text(r));
              }).toList(),
              onChanged: (v) => setState(() => _selectedRoute = v),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Your Comments',
                border: OutlineInputBorder(),
                hintText: 'How was the service today?',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('SUBMIT FEEDBACK'),
            ),
          ],
        ),
      ),
    );
  }
}
