import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Route $routeId Details')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF003366).withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route $routeId – City Centre ↔ UoG',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                ),
                const SizedBox(height: 5),
                const Text('Total Distance: 12 km | Est. Time: 30 min', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/schedule/$routeId'),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('View Schedule'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/student-home'), // Should ideally switch to Map tab
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View on Map'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('STOPS ON THIS ROUTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Column(
                    children: [
                      Icon(index == 0 ? Icons.trip_origin : (index == 4 ? Icons.location_on : Icons.radio_button_checked), 
                           color: index == 0 || index == 4 ? const Color(0xFF003366) : Colors.grey),
                      if (index != 4) Container(width: 2, height: 20, color: Colors.grey.shade300),
                    ],
                  ),
                  title: Text('Stop ${index + 1} Name'),
                  subtitle: Text('Arrival approx. ${7 + (index * 10)}:30 AM'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
