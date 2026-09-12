import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  Future<void> _showImagePickerOptions(BuildContext context, DriverProvider provider) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Select Profile Photo', style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, provider, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, provider, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, DriverProvider provider, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        await provider.updateProfileImage(base64Image);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        final driver = provider.driver;
        if (driver == null) return const Center(child: Text('Profile error'));

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              _buildHeader(context, provider, driver),
              const SizedBox(height: 40),
              _buildInfoSection(driver),
              const SizedBox(height: 40),
              _buildActions(context),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DriverProvider provider, dynamic driver) {
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
                onPressed: () => _showImagePickerOptions(context, provider),
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
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                context.go('/role-selection');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
