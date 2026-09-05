import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/dashboard_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1565C0);
    const Color backgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Control",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue),
            ),
            const Text("Management & System Reports", style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 32),
            
            // Safe Row/Column structure
            Row(
              children: [
                Expanded(child: _buildItem(context, 'Students', Icons.school, '/manage-students')),
                const SizedBox(width: 16),
                Expanded(child: _buildItem(context, 'Drivers', Icons.person_pin, '/manage-drivers')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildItem(context, 'Buses', Icons.directions_bus, '/manage-buses')),
                const SizedBox(width: 16),
                Expanded(child: _buildItem(context, 'Routes', Icons.route, '/manage-routes')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildItem(context, 'Schedules', Icons.schedule, '/manage-schedules')),
                const SizedBox(width: 16),
                Expanded(child: _buildItem(context, 'Live Maps', Icons.map, '/live-tracking')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildItem(context, 'Notice Hub', Icons.notification_add, '/manage-notices')),
                const SizedBox(width: 16),
                Expanded(child: _buildItem(context, 'Analytics', Icons.analytics, '/system-reports')),
              ],
            ),
            
            const SizedBox(height: 32),
            
            _buildActionTile(context, "Feedback Board", Icons.feedback_outlined, () => context.push('/view-feedback')),
            const SizedBox(height: 12),
            _buildActionTile(context, "Logout System", Icons.power_settings_new_rounded, () => context.go('/login')),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String route) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: DashboardCard(
        title: title, 
        value: '', 
        icon: icon, 
        color: const Color(0xFF1565C0),
        onTap: () => context.push(route),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: const Color(0xFF1565C0).withOpacity(0.1))
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(title, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF1565C0)),
      ),
    );
  }
}
