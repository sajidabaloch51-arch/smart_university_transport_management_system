import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/dashboard_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Definitive colors to ensure visibility
    const Color primaryBlue = Color(0xFF1565C0);
    const Color scaffoldBg = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Welcome Student",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const Text(
            "University of Gwadar Transport System",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Replaced GridView with Row-based layout for total stability
          _buildDashboardRow(context, [
            _dashboardItem('Buses', Icons.directions_bus, '/student-routes'),
            _dashboardItem('Schedule', Icons.calendar_month, '/schedule'),
          ]),
          const SizedBox(height: 16),
          _buildDashboardRow(context, [
            _dashboardItem('Tracking', Icons.location_on, '/live-tracking'),
            _dashboardItem('Notices', Icons.notifications, '/notices'),
          ]),
          const SizedBox(height: 16),
          _buildDashboardRow(context, [
            _dashboardItem('Feedback', Icons.feedback, '/feedback'),
            _dashboardItem('My Profile', Icons.person, '/personal-info'),
          ]),
          
          const SizedBox(height: 40),
          _buildFeedbackBanner(context, primaryBlue),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDashboardRow(BuildContext context, List<Widget> items) {
    return Row(
      children: items.map((item) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: item,
        ),
      )).toList(),
    );
  }

  Widget _dashboardItem(String title, IconData icon, String route) {
    return Builder(
      builder: (context) => AspectRatio(
        aspectRatio: 1.4,
        child: DashboardCard(
          title: title,
          value: '',
          icon: icon,
          color: const Color(0xFF1565C0),
          onTap: () => context.push(route),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Have feedback?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Text(
                  "Help us improve",
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/feedback'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );
  }
}
