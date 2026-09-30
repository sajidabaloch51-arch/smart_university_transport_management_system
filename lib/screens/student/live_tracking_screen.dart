import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Google Maps Integration Placeholder', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          // Tracking Info Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ETA', style: TextStyle(color: AppColors.grey)),
                            Text('8 Minutes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 30),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTrackInfo(Icons.person, 'Driver', 'Ali Ahmed'),
                        _buildTrackInfo(Icons.speed, 'Bus Speed', '40 km/h'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Student/Bus Location Icons (Mock)
          const Positioned(
            top: 200,
            left: 100,
            child: Icon(Icons.person_pin_circle, color: AppColors.secondary, size: 40),
          ),
          const Positioned(
            top: 300,
            right: 120,
            child: Icon(Icons.directions_bus, color: AppColors.primary, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
