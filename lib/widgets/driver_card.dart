import 'package:flutter/material.dart';
import '../models/driver_model.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;

  const DriverCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 32,
                backgroundImage: driver.profileImg.isNotEmpty 
                    ? NetworkImage(driver.profileImg) 
                    : null,
                child: driver.profileImg.isEmpty 
                    ? const Icon(Icons.person, size: 35) 
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bus: ${driver.assignedBusNumber}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    'Route: ${driver.assignedRouteName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: driver.isOnDuty ? Colors.greenAccent : Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                driver.isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
