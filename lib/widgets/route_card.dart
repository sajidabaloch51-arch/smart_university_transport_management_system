import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class RouteCard extends StatelessWidget {
  final String busName;
  final String startPoint;
  final String endPoint;
  final String time;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.busName,
    required this.startPoint,
    required this.endPoint,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  busName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.secondaryColor, size: 20),
                const SizedBox(width: 8),
                Text(startPoint, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 9),
              child: SizedBox(
                height: 20,
                child: VerticalDivider(thickness: 1, color: Colors.grey),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(endPoint, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
