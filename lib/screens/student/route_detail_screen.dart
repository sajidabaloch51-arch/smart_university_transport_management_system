import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../models/route_model.dart';
import '../../widgets/empty_state_widget.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text('Route $routeId Details')),
      body: StreamBuilder<RouteModel?>(
        stream: firestore.getRoute(routeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return const EmptyStateWidget(
              message: "Route details not found.",
              icon: Icons.search_off,
            );
          }

          final route = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(route),
                const SizedBox(height: 32),
                const Text(
                  'Stops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStopTimeline(route.stops),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'View Schedule', 
                  onPressed: () => context.push('/schedule', extra: route.id)
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Track Bus',
                  onPressed: () => context.push('/live-tracking', extra: route.id),
                  color: AppColors.success,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(RouteModel route) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.route, 'Route Name', route.routeName),
            const Divider(height: 30),
            _buildInfoRow(Icons.straighten, 'Total Distance', route.totalDistance),
            const Divider(height: 30),
            _buildInfoRow(Icons.timer_outlined, 'Estimated Duration', route.estimatedDuration),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildStopTimeline(List<RouteStop> stops) {
    return Column(
      children: List.generate(stops.length, (index) {
        final stop = stops[index];
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index == stops.length - 1 ? AppColors.primary : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (index != stops.length - 1)
                  Container(width: 2, height: 40, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  stop.stopName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
