import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/maps_launcher_service.dart';
import '../../widgets/custom_button.dart';
import '../../models/route_model.dart';

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
              const SizedBox(height: 24),
              const Text('Live Route View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMockMapView(),
              const SizedBox(height: 30),
              const Text('Route Stop Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTimeline(route.viaStops),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Navigate with Google Maps',
                icon: Icons.navigation,
                onPressed: () => _launchGoogleMapsNavigation(context, provider),
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

  Widget _buildMockMapView() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=25.12,62.32&zoom=13&size=600x300&maptype=roadmap'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Interactive Map Mockup', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchGoogleMapsNavigation(
    BuildContext context,
    DriverProvider provider,
  ) async {
    final route = provider.assignedRoute;
    final pos = provider.currentPosition;

    // Prefer last route stop as destination; else first stop with coords
    double? destLat;
    double? destLng;
    if (route != null) {
      final stops = [...route.stops]..sort((a, b) => a.order.compareTo(b.order));
      final withCoords = stops.where((s) => s.lat != 0 && s.lng != 0).toList();
      if (withCoords.isNotEmpty) {
        destLat = withCoords.last.lat;
        destLng = withCoords.last.lng;
      }
    }

    if (destLat == null || destLng == null) {
      if (pos != null) {
        await MapsLauncherService.openLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          label: route?.routeName ?? 'My route',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No route GPS points yet. Admin must add lat/lng on the route, or start duty for GPS.',
            ),
          ),
        );
      }
      return;
    }

    final originLat = pos?.latitude ?? destLat;
    final originLng = pos?.longitude ?? destLng;
    final ok = await MapsLauncherService.openDirections(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Opening Google Maps navigation…'
              : 'Could not open Google Maps. Is it installed?',
        ),
        backgroundColor: ok ? Colors.blue : Colors.red,
      ),
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
                subtitle: Text("Vehicle: ${s.vehicleNo} | ${s.shift}"),
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

  Widget _buildRouteSummary(RouteModel route) {
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
                  Text('Route No: ${route.routeNumber}', style: const TextStyle(color: Colors.blueGrey)),
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
              _summaryStat(Icons.location_on, route.startLocation, 'Start'),
              _summaryStat(Icons.flag, route.endLocation, 'End'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat(Icons.straighten, route.distanceKm, 'Distance'),
              _summaryStat(Icons.timer_outlined, route.estimatedTime, 'Duration'),
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
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTimeline(List<String> stops) {
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
                  Text(stop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
