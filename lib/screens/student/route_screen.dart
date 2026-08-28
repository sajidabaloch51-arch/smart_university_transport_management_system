import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/route_card.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Routes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RouteCard(
            routeName: "Bus A",
            busNumber: "UOG-001",
            startPoint: "Gwadar City",
            endPoint: "University",
            departureTime: "7:30 AM",
            onTap: () => context.push('/route-detail/A'),
          ),
          RouteCard(
            routeName: "Bus B",
            busNumber: "UOG-002",
            startPoint: "Marine Drive",
            endPoint: "University",
            departureTime: "8:00 AM",
            onTap: () => context.push('/route-detail/B'),
          ),
          RouteCard(
            routeName: "Bus C",
            busNumber: "UOG-003",
            startPoint: "East Bay",
            endPoint: "University",
            departureTime: "8:15 AM",
            onTap: () => context.push('/route-detail/C'),
          ),
        ],
      ),
    );
  }
}
