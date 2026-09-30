import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RouteCard extends StatelessWidget {
  final String routeName;
  final String busNumber;
  final String startPoint;
  final String endPoint;
  final String departureTime;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.routeName,
    required this.busNumber,
    required this.startPoint,
    required this.endPoint,
    required this.departureTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  routeName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    busNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.circle, color: AppColors.secondary, size: 12),
                const SizedBox(width: 8),
                Text(startPoint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: SizedBox(
                height: 20,
                child: VerticalDivider(thickness: 1, color: Colors.grey),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(endPoint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(departureTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
