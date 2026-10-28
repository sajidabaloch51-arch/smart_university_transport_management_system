import 'package:flutter/material.dart';
import '../models/driver_model.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  /// When set (e.g. from today's assigned duty), override profile bus/route.
  final String? busNoOverride;
  final String? routeOverride;

  const DriverCard({
    super.key,
    required this.driver,
    this.onEdit,
    this.onDelete,
    this.busNoOverride,
    this.routeOverride,
  });

  bool get _hasBus {
    final v = (busNoOverride ?? driver.assignedBusNumber).trim();
    return v.isNotEmpty && v.toLowerCase() != 'not assigned';
  }

  bool get _hasRoute {
    final v = (routeOverride ?? driver.assignedRouteName).trim();
    return v.isNotEmpty && v.toLowerCase() != 'not assigned';
  }

  String get _busLabel {
    if (!_hasBus) return 'Bus: Not Assigned';
    return 'Bus No: ${busNoOverride ?? driver.assignedBusNumber}';
  }

  String get _routeLabel {
    if (!_hasRoute) return 'Route: Not Assigned';
    return 'Route: ${routeOverride ?? driver.assignedRouteName}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.greenAccent;
      case 'inactive':
        return Colors.redAccent;
      case 'on leave':
        return Colors.amberAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, size: 45, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _busLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        _routeLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(
                            driver.status.isEmpty ? 'Unknown' : driver.status,
                            _statusColor(driver.status),
                          ),
                          _chip(
                            driver.isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                            driver.isOnDuty
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          if (!_hasRoute && !_hasBus)
                            _chip('UNASSIGNED', Colors.orangeAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onEdit != null || onDelete != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
