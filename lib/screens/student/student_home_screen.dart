import 'package:flutter/material.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Home')),
      body: const Center(
        child: Text('Welcome Student!'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'My Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Live Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notices'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
