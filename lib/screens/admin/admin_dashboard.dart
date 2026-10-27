import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../../services/feedback_service.dart';
import '../../services/firestore_seed_service.dart';
import '../../services/live_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Stream<List<DriverModel>>? _driversStream;
  Stream<List<RouteModel>>? _routesStream;
  Stream<List<ScheduleModel>>? _schedulesStream;
  bool _statsReady = false;

  @override
  void initState() {
    super.initState();
    // Paint the dashboard shell first — attach Firestore after the first frame.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _driversStream = context.read<DriverProvider>().streamDrivers();
        _routesStream = context.read<RouteProvider>().streamRoutes();
        _schedulesStream = context.read<ScheduleProvider>().streamSchedules();
        _statsReady = true;
      });
    });
  }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use Logout button to exit session'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/role-selection');
                }
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Management Modules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildModulesGrid(context, crossAxisCount, isDesktop, isTablet),
            const SizedBox(height: 24),
            const _FeedbackBoardTile(),
            const SizedBox(height: 12),
            const _SeedSampleDataTile(),
            const SizedBox(height: 24),
          ],
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
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 35,
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'System Control Panel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // Placeholders so the screen is interactive immediately.
    if (!_statsReady ||
        _driversStream == null ||
        _routesStream == null ||
        _schedulesStream == null) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Drivers', '…', 'Loading', Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Routes', '…', 'Loading', Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Today's Duty",
                  '…',
                  'Loading',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'System Health',
                  'Good',
                  'All systems normal',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StreamBuilder<List<DriverModel>>(
                stream: _driversStream,
                builder: (context, snapshot) {
                  final drivers = snapshot.data ?? const <DriverModel>[];
                  final activeDrivers =
                      drivers.where((d) => d.isOnDuty).length;
                  return _buildStatCard(
                    'Drivers',
                    snapshot.hasData ? '${drivers.length}' : '…',
                    'Active: $activeDrivers',
                    Colors.blue,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<RouteModel>>(
                stream: _routesStream,
                builder: (context, snapshot) {
                  final routes = snapshot.data ?? const <RouteModel>[];
                  return _buildStatCard(
                    'Routes',
                    snapshot.hasData ? '${routes.length}' : '…',
                    'Active Now',
                    Colors.green,
                  );
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
                stream: _schedulesStream,
                builder: (context, snapshot) {
                  final schedules = snapshot.data ?? const <ScheduleModel>[];
                  final today = DateTime.now();
                  final todaySchedules = schedules
                      .where(
                        (s) =>
                            s.date.day == today.day &&
                            s.date.month == today.month &&
                            s.date.year == today.year,
                      )
                      .length;
                  return _buildStatCard(
                    "Today's Duty",
                    snapshot.hasData ? '$todaySchedules' : '…',
                    'Schedules',
                    Colors.orange,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'System Health',
                'Good',
                'All systems normal',
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subLabel,
    Color color,
  ) {
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(
    BuildContext context,
    int crossAxisCount,
    bool isDesktop,
    bool isTablet,
  ) {
    final modules = <({String title, IconData icon, Color color, String path})>[
      (
        title: 'Verification',
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF003366),
        path: '/student-verification',
      ),
      (
        title: 'Students',
        icon: Icons.school_outlined,
        color: const Color(0xFF6366F1),
        path: '/manage-students',
      ),
      (
        title: 'Drivers',
        icon: Icons.person_pin_outlined,
        color: const Color(0xFF0EA5E9),
        path: '/manage-drivers',
      ),
      (
        title: 'Buses',
        icon: Icons.directions_bus_outlined,
        color: const Color(0xFFF59E0B),
        path: '/manage-buses',
      ),
      (
        title: 'Routes',
        icon: Icons.route_outlined,
        color: const Color(0xFF10B981),
        path: '/manage-routes',
      ),
      (
        title: 'Schedules',
        icon: Icons.schedule_outlined,
        color: const Color(0xFF8B5CF6),
        path: '/manage-schedules',
      ),
      (
        title: 'Duties',
        icon: Icons.assignment_ind_outlined,
        color: const Color(0xFF7C3AED),
        path: '/manage-duties',
      ),
      (
        title: 'Live Track',
        icon: Icons.map_outlined,
        color: const Color(0xFF06B6D4),
        path: '/live-tracking',
      ),
      (
        title: 'Notices',
        icon: Icons.notification_add_outlined,
        color: const Color(0xFFEF4444),
        path: '/manage-notices',
      ),
      (
        title: 'Alerts',
        icon: Icons.add_alert_outlined,
        color: const Color(0xFFDC2626),
        path: '/manage-alerts',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isDesktop ? 2.0 : (isTablet ? 1.6 : 1.35),
      ),
      itemBuilder: (context, index) {
        final m = modules[index];
        return DashboardCard(
          title: m.title,
          value: '',
          icon: m.icon,
          color: m.color,
          onTap: () => context.push(m.path),
        );
      },
    );
  }
}

class _SeedSampleDataTile extends StatefulWidget {
  const _SeedSampleDataTile();

  @override
  State<_SeedSampleDataTile> createState() => _SeedSampleDataTileState();
}

class _SeedSampleDataTileState extends State<_SeedSampleDataTile> {
  bool _busy = false;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed sample data?'),
        content: const Text(
          'TEST DATA ONLY.\n\n'
          'Writes demo routes, buses, drivers, schedules, duties and alerts '
          'into Firestore so you can test the app. Safe to re-run.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seed now'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      LiveFirestore.log('AdminSeed', collection: '_meta/seed');
      final done = await FirestoreSeedService.ensureSeedData(force: true);
      if (!done) {
        throw StateError('Firestore not reachable. Check internet / project.');
      }
      LiveFirestore.restartAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample data seeded (TEST DATA).'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Seed sample data failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: ListTile(
        onTap: _busy ? null : _run,
        leading: _busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.science_outlined, color: Colors.orange.shade800),
        title: Text(
          'Seed sample data (TEST DATA)',
          style: TextStyle(
            color: Colors.orange.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Creates demo routes / drivers / duties for testing',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _FeedbackBoardTile extends StatefulWidget {
  const _FeedbackBoardTile();

  @override
  State<_FeedbackBoardTile> createState() => _FeedbackBoardTileState();
}

class _FeedbackBoardTileState extends State<_FeedbackBoardTile> {
  Stream<int>? _newCountStream;

  @override
  void initState() {
    super.initState();
    // Defer feedback count so opening Admin is not blocked by another query.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _newCountStream = FeedbackService().streamNewCount();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade900;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: () => context.push('/view-feedback'),
        leading: Icon(Icons.feedback_outlined, color: color),
        title: Text(
          'View Feedback Board',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        trailing: _newCountStream == null
            ? const Icon(Icons.chevron_right)
            : StreamBuilder<int>(
                stream: _newCountStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count new',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
