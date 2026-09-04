import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/driver_card.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/notice_card.dart';
import 'driver_route_screen.dart';
import 'duty_screen.dart';
import 'driver_notice_screen.dart';
import 'driver_profile_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure driver provider is initialized if it wasn't already
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      if (provider.driver == null) {
        provider.init('driver_123');
      }
    });
  }

  final List<Widget> _pages = [
    const DashboardSummary(),
    const DriverRouteScreen(),
    const DutyScreen(),
    const DriverNoticeScreen(),
    const DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Route'),
          NavigationDestination(icon: Icon(Icons.work_history_outlined), selectedIcon: Icon(Icons.work_history), label: 'Duty'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardSummary extends StatelessWidget {
  const DashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.driver == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Setting up your dashboard..."),
                ],
              ),
            ),
          );
        }

        if (provider.driver == null) {
          return const Center(child: Text("Error loading driver data. Tap refresh."));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Dashboard'),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.init(provider.driver!.uid)),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,', style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text(provider.driver!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                DriverCard(driver: provider.driver!),
                const SizedBox(height: 30),
                
                const SectionHeader(title: "Today's Schedule"),
                if (provider.todaySchedules.isEmpty)
                  const EmptyStateBox(message: 'No schedules assigned for today.')
                else
                  ...provider.todaySchedules.map((s) => ScheduleCard(schedule: s)),
                
                const SizedBox(height: 30),
                
                const SectionHeader(title: "Recent Alerts"),
                if (provider.notices.isEmpty)
                  const EmptyStateBox(message: 'No active transport alerts.')
                else
                  ...provider.notices.take(2).map((n) => NoticeCard(notice: n, onReadMore: () {})),
                
                const SizedBox(height: 30),
                
                const SectionHeader(title: "Quick Actions"),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.5,
                  children: [
                    _ActionBtn(icon: Icons.map, label: 'Open Map', color: Colors.green, onTap: () {}),
                    _ActionBtn(icon: Icons.support_agent, label: 'Help Desk', color: Colors.orange, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}

class EmptyStateBox extends StatelessWidget {
  final String message;
  const EmptyStateBox({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
