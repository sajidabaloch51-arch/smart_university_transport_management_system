import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/driver_provider.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        final driver = provider.driver;
        if (driver == null) return const Center(child: Text('Profile error'));

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildHeader(driver),
                const SizedBox(height: 40),
                _buildInfoSection(driver),
                const SizedBox(height: 40),
                _buildActions(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(dynamic driver) {
    ImageProvider<Object>? imageProvider;
    if (driver.profileImg != null && driver.profileImg.isNotEmpty) {
      if (driver.profileImg.startsWith('http')) {
        imageProvider = NetworkImage(driver.profileImg);
      } else {
        try {
          imageProvider = MemoryImage(base64Decode(driver.profileImg));
        } catch (e) {
          debugPrint("Error decoding base64 image: $e");
        }
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
                child: imageProvider == null ? const Icon(Icons.person, size: 80, color: Colors.blue) : null,
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(driver.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text('Employee ID: ${driver.driverId}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildInfoSection(dynamic driver) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _infoTile(Icons.email_outlined, 'Email Address', driver.email),
          _infoTile(Icons.phone_outlined, 'Phone Number', driver.phone),
          _infoTile(Icons.directions_bus_outlined, 'Assigned Bus', driver.assignedBusNumber),
          _infoTile(Icons.route_outlined, 'Assigned Route', driver.assignedRouteName),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => context.push('/edit-driver-profile'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Edit Profile Information'),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
