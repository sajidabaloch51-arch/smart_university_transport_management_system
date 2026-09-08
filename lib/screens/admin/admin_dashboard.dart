import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    
    int crossAxisCount = 2;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 3;
    }

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                    color: AppColors.primary.withOpacity(0.3),
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
                        Text(
                          "Welcome Back,",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          "Administrator",
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: 0.5
                          ),
                        ),
                        Text(
                          "System Control Panel", 
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                "Management Modules",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isDesktop ? 2.0 : (isTablet ? 1.8 : 1.7),
              children: [
                DashboardCard(
                  title: 'Manage Students', 
                  value: '', 
                  icon: Icons.school_outlined, 
                  color: const Color(0xFF6366F1), 
                  onTap: () => context.push('/manage-students'),
                ),
                DashboardCard(
                  title: 'Manage Drivers', 
                  value: '', 
                  icon: Icons.person_pin_outlined, 
                  color: const Color(0xFF0EA5E9), 
                  onTap: () => context.push('/manage-drivers'),
                ),
                DashboardCard(
                  title: 'Manage Buses', 
                  value: '', 
                  icon: Icons.directions_bus_outlined, 
                  color: const Color(0xFFF59E0B), 
                  onTap: () => context.push('/manage-buses'),
                ),
                DashboardCard(
                  title: 'Manage Routes', 
                  value: '', 
                  icon: Icons.route_outlined, 
                  color: const Color(0xFF10B981), 
                  onTap: () => context.push('/manage-routes'),
                ),
                DashboardCard(
                  title: 'Manage Schedules', 
                  value: '', 
                  icon: Icons.schedule_outlined, 
                  color: const Color(0xFF8B5CF6), 
                  onTap: () => context.push('/manage-schedules'),
                ),
                DashboardCard(
                  title: 'Live Tracking', 
                  value: '', 
                  icon: Icons.map_outlined, 
                  color: const Color(0xFF06B6D4), 
                  onTap: () => context.push('/live-tracking'),
                ),
                DashboardCard(
                  title: 'Post Notices', 
                  value: '', 
                  icon: Icons.notification_add_outlined, 
                  color: const Color(0xFFEF4444), 
                  onTap: () => context.push('/manage-notices'),
                ),
                DashboardCard(
                  title: 'System Reports', 
                  value: '', 
                  icon: Icons.analytics_outlined, 
                  color: const Color(0xFF64748B), 
                  onTap: () => context.push('/system-reports'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionTile(
              title: "View Feedback Board",
              icon: Icons.feedback_outlined,
              color: Colors.amber.shade900,
              onTap: () => context.push('/view-feedback'),
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              title: "Sign Out",
              icon: Icons.power_settings_new_rounded,
              color: Colors.redAccent,
              onTap: () => context.go('/login'),
            ),
            const SizedBox(height: 24),
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
