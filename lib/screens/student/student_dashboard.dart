import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../providers/auth_provider.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Student Portal"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (context.mounted) context.go('/login');
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
            // Prominent Header Card
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
                    child: Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back!",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          "Sajida Abdullah",
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: 0.5
                          ),
                        ),
                        Text(
                          "UOG-2022-123", 
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
                "Quick Actions",
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isDesktop ? 1.6 : 1.35,
              children: [
                DashboardCard(
                  title: 'Student Profile', 
                  value: '', 
                  icon: Icons.person_outline_rounded, 
                  color: const Color(0xFF6366F1), // Indigo
                  onTap: () => context.push('/personal-info'),
                ),
                DashboardCard(
                  title: 'Bus/Routes', 
                  value: '', 
                  icon: Icons.directions_bus_rounded, 
                  color: const Color(0xFF0EA5E9), // Sky
                  onTap: () => context.push('/student-routes'),
                ),
                DashboardCard(
                  title: 'Transport Schedule', 
                  value: '', 
                  icon: Icons.event_note_rounded, 
                  color: const Color(0xFFF59E0B), // Amber
                  onTap: () => context.push('/schedule'),
                ),
                DashboardCard(
                  title: 'Live Tracking', 
                  value: '', 
                  icon: Icons.location_searching_rounded, 
                  color: const Color(0xFF10B981), // Emerald
                  onTap: () => context.push('/live-tracking'),
                ),
                DashboardCard(
                  title: 'Notifications', 
                  value: '', 
                  icon: Icons.notifications_active_rounded, 
                  color: const Color(0xFFEF4444), // Red
                  onTap: () => context.push('/notices'),
                ),
                DashboardCard(
                  title: 'Feedback', 
                  value: '', 
                  icon: Icons.rate_review_rounded, 
                  color: const Color(0xFF8B5CF6), // Violet
                  onTap: () => context.push('/feedback'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Helpful Tip or Notice section could go here
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Bus schedules are subject to change during exam weeks. Please check notifications regularly.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
