import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/custom_button.dart';

class DriverRouteScreen extends StatelessWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        final route = provider.assignedRoute;
        if (route == null) return const Center(child: Text('Route details not assigned.'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRouteSummary(route),
              const SizedBox(height: 30),
              const Text('Stop Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTimeline(route.stops),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Open Google Maps', 
                icon: Icons.map_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Launching Google Maps Navigation...'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'View Full Schedule', 
                color: Colors.orange,
                icon: Icons.calendar_today,
                onPressed: () => _showFullSchedule(context, provider),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showFullSchedule(BuildContext context, DriverProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Route Schedule",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (provider.todaySchedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No schedule details available.")),
              )
            else
              ...provider.todaySchedules.map((s) => ListTile(
                leading: const Icon(Icons.schedule, color: Colors.orange),
                title: Text("${s.departureTime} - ${s.arrivalTime}"),
                subtitle: Text("Bus: ${s.busNumber} | ${s.days.join(', ')}"),
                contentPadding: EdgeInsets.zero,
              )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("CLOSE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSummary(dynamic route) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.routeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('Route ID: ${route.routeNumber}', style: const TextStyle(color: Colors.blueGrey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat(Icons.straighten, route.totalDistance, 'Distance'),
              _summaryStat(Icons.timer_outlined, route.estimatedDuration, 'Duration'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade800),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTimeline(List stops) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        bool isLast = index == stops.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 18,
                  height: 16,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.green : (isLast ? Colors.red : Colors.blue),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast) Container(width: 2, height: 45, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.stopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Scheduled Stop ${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
