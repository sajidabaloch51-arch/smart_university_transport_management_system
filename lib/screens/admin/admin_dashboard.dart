import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../providers/auth_provider.dart';

import '../../providers/driver_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/driver_model.dart';
import '../../models/route_model.dart';
import '../../models/schedule_model.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 3;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use Logout button to exit session'), duration: Duration(seconds: 1)),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/role-selection');
              }
            },
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/role-selection');
                }
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsSection(driverProvider, routeProvider, scheduleProvider),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  "Management Modules",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 16),
              _buildModulesGrid(context, crossAxisCount, isDesktop, isTablet),
              const SizedBox(height: 24),
              _buildActionTile(
                title: "View Feedback Board",
                icon: Icons.feedback_outlined,
                color: Colors.amber.shade900,
                onTap: () => context.push('/view-feedback'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  "Administrator",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
                Text("System Control Panel", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DriverProvider dp, RouteProvider rp, ScheduleProvider sp) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<List<DriverModel>>(
                stream: dp.streamDrivers(),
                builder: (context, snapshot) {
                  final drivers = snapshot.data ?? [];
                  final activeDrivers = drivers.where((d) => d.isOnDuty).length;
                  return _buildStatCard("Drivers", "${drivers.length}", "Active: $activeDrivers", Colors.blue);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<RouteModel>>(
                stream: rp.streamRoutes(),
                builder: (context, snapshot) {
                  final routes = snapshot.data ?? [];
                  return _buildStatCard("Routes", "${routes.length}", "Active Now", Colors.green);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<List<ScheduleModel>>(
                stream: sp.streamSchedules(),
                builder: (context, snapshot) {
                  final schedules = snapshot.data ?? [];
                  final today = DateTime.now();
                  final todaySchedules = schedules.where((s) => s.date.day == today.day && s.date.month == today.month && s.date.year == today.year).length;
                  return _buildStatCard("Today's Duty", "$todaySchedules", "Schedules", Colors.orange);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("System Health", "Good", "All systems normal", Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context, int crossAxisCount, bool isDesktop, bool isTablet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isDesktop ? 2.0 : (isTablet ? 1.8 : 1.7),
      children: [
        DashboardCard(title: 'Student Verification', value: '', icon: Icons.verified_user_outlined, color: const Color(0xFF003366), onTap: () => context.push('/student-verification')),
        DashboardCard(title: 'Manage Students', value: '', icon: Icons.school_outlined, color: const Color(0xFF6366F1), onTap: () => context.push('/manage-students')),
        DashboardCard(title: 'Manage Drivers', value: '', icon: Icons.person_pin_outlined, color: const Color(0xFF0EA5E9), onTap: () => context.push('/manage-drivers')),
        DashboardCard(title: 'Manage Buses', value: '', icon: Icons.directions_bus_outlined, color: const Color(0xFFF59E0B), onTap: () => context.push('/manage-buses')),
        DashboardCard(title: 'Manage Routes', value: '', icon: Icons.route_outlined, color: const Color(0xFF10B981), onTap: () => context.push('/manage-routes')),
        DashboardCard(title: 'Manage Schedules', value: '', icon: Icons.schedule_outlined, color: const Color(0xFF8B5CF6), onTap: () => context.push('/manage-schedules')),
        DashboardCard(title: 'Live Tracking', value: '', icon: Icons.map_outlined, color: const Color(0xFF06B6D4), onTap: () => context.push('/live-tracking')),
        DashboardCard(title: 'Post Notices', value: '', icon: Icons.notification_add_outlined, color: const Color(0xFFEF4444), onTap: () => context.push('/manage-notices')),
      ],
    );
  }

  Widget _buildActionTile({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: color.withValues(alpha: 0.2))
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
