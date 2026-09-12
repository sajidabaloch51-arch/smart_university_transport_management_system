import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/custom_button.dart';

class DutyScreen extends StatelessWidget {
  const DutyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        final driver = provider.driver;
        if (driver == null) return const Center(child: Text('Error loading status'));

        bool isOnDuty = driver.isOnDuty;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Live Status Indicator
              _StatusBadge(isOnDuty: isOnDuty),
              const SizedBox(height: 40),
              
              // Real-time Stats Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _StatTile(
                      icon: Icons.timer, 
                      value: _formatDuration(provider.dutyDuration), 
                      label: 'Duty Timer'
                    ),
                    _StatTile(
                      icon: Icons.speed_rounded, 
                      value: '${provider.currentPosition?.speed.toStringAsFixed(1) ?? "0.0"} km/h', 
                      label: 'Current Speed'
                    ),
                    _StatTile(
                      icon: Icons.my_location, 
                      value: '${provider.currentPosition?.latitude.toStringAsFixed(4) ?? "0.0"}, ${provider.currentPosition?.longitude.toStringAsFixed(4) ?? "0.0"}', 
                      label: 'GPS Coordinates'
                    ),
                    _StatTile(
                      icon: Icons.bus_alert, 
                      value: provider.assignedRoute?.stops.first.stopName ?? 'N/A', 
                      label: 'Next Stop'
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Start/End Duty Toggle
              CustomButton(
                text: isOnDuty ? 'END DUTY' : 'START DUTY',
                color: isOnDuty ? Colors.red : Colors.green,
                isLoading: provider.isLoading,
                icon: isOnDuty ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded,
                onPressed: () => provider.toggleDuty(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOnDuty;
  const _StatusBadge({required this.isOnDuty});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: isOnDuty ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isOnDuty ? Colors.green : Colors.red, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isOnDuty ? Icons.radar_rounded : Icons.offline_bolt_rounded, 
               size: 50, color: isOnDuty ? Colors.green : Colors.red),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnDuty ? 'TRACKING ACTIVE' : 'TRACKING OFFLINE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isOnDuty ? Colors.green.shade900 : Colors.red.shade900),
              ),
              Text(
                isOnDuty ? 'Broadcasting live location' : 'Duty session not started',
                style: TextStyle(color: isOnDuty ? Colors.green.shade700 : Colors.red.shade700, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(height: 12),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
