import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/driver_card.dart';
import '../../widgets/schedule_card.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/dashboard_card.dart';
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
    // Ensure driver provider is initialized with the logged in user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      
      if (authProvider.uid != null) {
        driverProvider.init(authProvider.uid!);
      } else if (driverProvider.driver == null) {
        driverProvider.init('driver_123');
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Route'),
          NavigationDestination(icon: Icon(Icons.work_history_outlined), label: 'Duty'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardSummary extends StatelessWidget {
  const DashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1565C0);

    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.driver == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (provider.driver == null) {
          return const Center(child: Text("Error loading data."));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Driver Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: primaryBlue,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => provider.init(provider.driver!.uid)),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,', style: TextStyle(fontSize: 16, color: Colors.black54)),
                Text(provider.driver!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryBlue)),
                const SizedBox(height: 24),
                
                DriverCard(driver: provider.driver!),
                const SizedBox(height: 32),
                
                _sectionTitle("Today's Duty"),
                if (provider.todaySchedules.isEmpty)
                  _emptyBox('No duty assigned for today.')
                else
                  ...provider.todaySchedules.map((s) => ScheduleCard(schedule: s)),
                
                const SizedBox(height: 32),
                
                _sectionTitle("Recent Alerts"),
                if (provider.notices.isEmpty)
                  _emptyBox('No active notices.')
                else
                  ...provider.notices.take(2).map((n) => NoticeCard(notice: n, onReadMore: () {})),
                
                const SizedBox(height: 32),
                
                _sectionTitle("Quick Tools"),
                Row(
                  children: [
                    Expanded(child: _toolBtn('Open Map', Icons.map, primaryBlue)),
                    const SizedBox(width: 16),
                    Expanded(child: _toolBtn('Help Desk', Icons.support_agent, primaryBlue)),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolBtn(String title, IconData icon, Color color) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: DashboardCard(title: title, value: '', icon: icon, color: color, onTap: () {}),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
    );
  }
}
