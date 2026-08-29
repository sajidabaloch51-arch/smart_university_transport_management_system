import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
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
              "Welcome, Administrator",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const Text("System Management & Control", style: TextStyle(color: Colors.grey)),
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
                  title: 'Manage Students', 
                  value: '', 
                  icon: Icons.school_outlined, 
                  color: Colors.blue,
                  onTap: () => context.push('/manage-students'),
                ),
                DashboardCard(
                  title: 'Manage Drivers', 
                  value: '', 
                  icon: Icons.person_pin_outlined, 
                  color: Colors.green,
                  onTap: () => context.push('/manage-drivers'),
                ),
                DashboardCard(
                  title: 'Manage Buses', 
                  value: '', 
                  icon: Icons.directions_bus_outlined, 
                  color: Colors.purple,
                  onTap: () => context.push('/manage-buses'),
                ),
                DashboardCard(
                  title: 'Manage Routes', 
                  value: '', 
                  icon: Icons.route_outlined, 
                  color: Colors.orange,
                  onTap: () => context.push('/manage-routes'),
                ),
                DashboardCard(
                  title: 'Manage Schedules', 
                  value: '', 
                  icon: Icons.schedule_outlined, 
                  color: Colors.indigo,
                  onTap: () => context.push('/manage-schedules'),
                ),
                DashboardCard(
                  title: 'View Live Tracking', 
                  value: '', 
                  icon: Icons.map_outlined, 
                  color: Colors.teal,
                  onTap: () => context.push('/live-tracking'),
                ),
                DashboardCard(
                  title: 'Transport Notices', 
                  value: '', 
                  icon: Icons.notification_add_outlined, 
                  color: Colors.redAccent,
                  onTap: () => context.push('/manage-notices'),
                ),
                DashboardCard(
                  title: 'System Reports', 
                  value: '', 
                  icon: Icons.analytics_outlined, 
                  color: Colors.blueGrey,
                  onTap: () => context.push('/system-reports'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              title: "View Feedback Board",
              icon: Icons.feedback_outlined,
              color: Colors.amber.shade900,
              onTap: () => context.push('/view-feedback'),
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              title: "Logout System",
              icon: Icons.power_settings_new_rounded,
              color: Colors.redAccent,
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: color.withOpacity(0.2))
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
