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
        if (driver == null) return const Center(child: Text('Error loading driver'));

        return Scaffold(
          appBar: AppBar(title: const Text('Duty Tracking')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Duty Status Card
                _buildDutyStatusCard(provider),
                const SizedBox(height: 32),
                
                // Live Stats Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _infoTile(Icons.speed, '${provider.currentPosition?.speed.toStringAsFixed(1) ?? "0.0"} km/h', 'Current Speed'),
                      _infoTile(Icons.my_location, '${provider.currentPosition?.latitude.toStringAsFixed(4) ?? "0.0"}, ${provider.currentPosition?.longitude.toStringAsFixed(4) ?? "0.0"}', 'Location'),
                      _infoTile(Icons.timer, _formatDuration(provider.dutyDuration), 'Duty Timer'),
                      _infoTile(Icons.bus_alert, provider.assignedRoute?.stops.first.stopName ?? 'N/A', 'Next Stop'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Toggle Button
                CustomButton(
                  text: driver.isOnDuty ? 'END DUTY' : 'START DUTY',
                  color: driver.isOnDuty ? Colors.red : Colors.green,
                  isLoading: provider.isLoading,
                  icon: driver.isOnDuty ? Icons.stop : Icons.play_arrow,
                  onPressed: () => provider.toggleDuty(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDutyStatusCard(DriverProvider provider) {
    bool isOnDuty = provider.driver?.isOnDuty ?? false;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOnDuty ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnDuty ? Colors.green : Colors.red, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            isOnDuty ? Icons.verified_user : Icons.gpp_bad, 
            size: 50, 
            color: isOnDuty ? Colors.green : Colors.red
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnDuty ? 'WORKING: ON DUTY' : 'NOT WORKING: OFF DUTY',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: isOnDuty ? Colors.green.shade900 : Colors.red.shade900
                ),
              ),
              Text(
                isOnDuty ? 'GPS Tracking Active' : 'GPS Tracking Stopped',
                style: TextStyle(color: isOnDuty ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            value, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
