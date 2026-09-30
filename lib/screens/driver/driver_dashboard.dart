import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notice_provider.dart';
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
    // Ensure driver provider is initialized with the logged in user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      
      if (authProvider.uid != null) {
        driverProvider.init(authProvider.uid!);
      }
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Driver Dashboard';
      case 1: return 'My Route';
      case 2: return 'Duty Tracking';
      case 3: return 'Official Notices';
      case 4: return 'My Profile';
      default: return 'Driver Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    
    final List<Widget> pages = [
      DashboardSummary(
        onNavigateToRoute: () => _onTabChanged(1),
        onNavigateToNotices: () => _onTabChanged(3),
      ),
      const DriverRouteScreen(),
      const DutyScreen(),
      const DriverNoticeScreen(),
      const DriverProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          _onTabChanged(0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use Logout button to exit session'), duration: Duration(seconds: 1)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedIndex != 0) {
                setState(() => _selectedIndex = 0);
              } else {
                context.go('/role-selection');
              }
            },
          ),
          title: Text(_getAppBarTitle()),
          actions: _selectedIndex == 0 ? [
            IconButton(
              icon: const Icon(Icons.refresh), 
              onPressed: () {
                if (driverProvider.driver != null) {
                  driverProvider.init(driverProvider.driver!.uid);
                }
              }
            ),
          ] : null,
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabChanged,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Route'),
            NavigationDestination(icon: Icon(Icons.work_history_outlined), selectedIcon: Icon(Icons.work_history), label: 'Duty'),
            NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notices'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardSummary extends StatelessWidget {
  final VoidCallback onNavigateToRoute;
  final VoidCallback onNavigateToNotices;
  const DashboardSummary({
    super.key, 
    required this.onNavigateToRoute,
    required this.onNavigateToNotices,
  });

  void _showHelpDesk(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transport Help Desk'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance? Contact our support team:'),
            SizedBox(height: 15),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue),
              title: Text('Emergency Contact'),
              subtitle: Text('+92 300 999 8888'),
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('Transport Office'),
              subtitle: Text('transport@uog.edu.pk'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.driver == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Setting up your dashboard..."),
              ],
            ),
          );
        }

        if (provider.driver == null) {
          return const Center(child: Text("Error loading data."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello,', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(provider.driver!.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              DriverCard(driver: provider.driver!),
              const SizedBox(height: 30),
              
              _sectionTitle("Today's Active Duties"),
              if (provider.todaySchedules.isEmpty)
                _emptyBox('No schedules assigned for today.')
              else
                ...provider.todaySchedules.map((s) => ScheduleCard(schedule: s)),
              
              const SizedBox(height: 30),
              
              _sectionTitle("Recent Alerts"),
              Builder(
                builder: (context) {
                  final adminNotices = Provider.of<NoticeProvider>(context).noticesForRole('driver');
                  if (adminNotices.isEmpty) {
                    return _emptyBox('No active transport alerts.');
                  }
                  return Column(
                    children: adminNotices
                        .take(2)
                        .map((n) => NoticeCard(notice: n, onReadMore: onNavigateToNotices))
                        .toList(),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              _sectionTitle("Quick Actions"),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 2.5,
                children: [
                  _ActionBtn(icon: Icons.map, label: 'Open Map', color: Colors.green, onTap: onNavigateToRoute),
                  _ActionBtn(icon: Icons.support_agent, label: 'Help Desk', color: Colors.orange, onTap: () => _showHelpDesk(context)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
