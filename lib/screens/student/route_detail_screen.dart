import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../models/route_model.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state_widget.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late Stream<RouteModel?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirestoreService().getRoute(widget.routeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Route ${widget.routeId} Details')),
      body: AsyncStateView<RouteModel?>(
        stream: _stream,
        timeout: const Duration(seconds: 12),
        isEmpty: (route) => route == null,
        emptyMessage: 'Route details not found.',
        onRetry: () {
          setState(() {
            _stream = FirestoreService().getRoute(widget.routeId);
          });
        },
        builder: (context, route) {
          if (route == null) {
            return const EmptyStateWidget(
              message: 'Route details not found.',
              icon: Icons.search_off,
            );
          }

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
                _buildStopTimeline(route),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'View Schedule',
                  onPressed: () =>
                      context.push('/schedule', extra: route.id),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Track Bus',
                  onPressed: () =>
                      context.push('/live-tracking', extra: route.id),
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
            _buildInfoRow(Icons.person, 'Driver', route.displayDriverName),
            const Divider(height: 30),
            _buildInfoRow(
              Icons.directions_bus,
              'Bus',
              route.busNo.isNotEmpty ? route.busNo : '—',
            ),
            const Divider(height: 30),
            _buildInfoRow(
              Icons.phone,
              'Driver phone',
              route.driverPhone.isNotEmpty ? route.driverPhone : '—',
            ),
            const Divider(height: 30),
            _buildInfoRow(Icons.straighten, 'Total Distance', route.distanceKm),
            const Divider(height: 30),
            _buildInfoRow(
              Icons.timer_outlined,
              'Estimated Duration',
              route.estimatedTime.isNotEmpty ? route.estimatedTime : '—',
            ),
            const Divider(height: 30),
            _buildInfoRow(
              Icons.schedule,
              'Departure / Arrival',
              '${route.cardDepartureTime} → ${route.cardArrivalTime}',
            ),
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
            Text(
              label,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStopTimeline(RouteModel route) {
    final stops = route.stops;
    if (stops.isEmpty) {
      return Text(
        'No stops listed for this route.',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }
    return Column(
      children: List.generate(stops.length, (index) {
        final stop = stops[index];
        final name = stop.stopName.trim().isNotEmpty
            ? stop.stopName.trim()
            : 'Stop ${index + 1}';
        String time = stop.timeLabel.trim();
        if (RouteModel.looksLikeDuration(time)) time = '';
        if (time.isEmpty && index == 0) {
          time = route.cardDepartureTime;
        } else if (time.isEmpty && index == stops.length - 1) {
          time = route.cardArrivalTime;
        }
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index == stops.length - 1
                        ? AppColors.primary
                        : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
