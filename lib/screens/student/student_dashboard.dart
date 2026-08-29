import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        actions: [
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Student",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const Text("Select a service to continue", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                DashboardCard(
                  title: 'View Bus List', 
                  value: '', 
                  icon: Icons.directions_bus_filled_outlined, 
                  color: AppColors.primary,
                  onTap: () => context.push('/student-routes'),
                ),
                DashboardCard(
                  title: 'Routes & Timings', 
                  value: '', 
                  icon: Icons.schedule_outlined, 
                  color: Colors.orange,
                  onTap: () => context.push('/schedule'),
                ),
                DashboardCard(
                  title: 'Track Bus on Map', 
                  value: '', 
                  icon: Icons.map_outlined, 
                  color: Colors.green,
                  onTap: () => context.push('/live-tracking'),
                ),
                DashboardCard(
                  title: 'Transport Notices', 
                  value: '', 
                  icon: Icons.notifications_active_outlined, 
                  color: Colors.red,
                  onTap: () => context.push('/notices'),
                ),
                DashboardCard(
                  title: 'Profile', 
                  value: '', 
                  icon: Icons.person_outline, 
                  color: Colors.teal,
                  onTap: () => context.push('/personal-info'),
                ),
                DashboardCard(
                  title: 'Logout', 
                  value: '', 
                  icon: Icons.power_settings_new_rounded, 
                  color: Colors.blueGrey,
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
