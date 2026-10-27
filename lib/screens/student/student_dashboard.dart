import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/route_provider.dart';
import '../../models/student_model.dart';
import '../../models/route_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  StudentModel? _student;
  bool _loadingStudent = true;
  late final Stream<List<RouteModel>> _routesStream;

  @override
  void initState() {
    super.initState();
    final routeProvider = context.read<RouteProvider>();
    final students = context.read<StudentProvider>();
    final uid = context.read<AuthProvider>().uid ?? '';
    _routesStream = routeProvider.streamRoutes();
    _student = students.peekStudent(uid);
    if (_student != null) _loadingStudent = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudent());
  }

  Future<void> _loadStudent() async {
    final uid = context.read<AuthProvider>().uid ?? '';
    if (uid.isEmpty) {
      if (mounted) setState(() => _loadingStudent = false);
      return;
    }
    final student = await context.read<StudentProvider>().getStudent(uid);
    if (!mounted) return;
    setState(() {
      _student = student;
      _loadingStudent = false;
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

    final authProvider = context.read<AuthProvider>();
    final student = _student;

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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Student Portal'),
          actions: [
            IconButton(
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/role-selection');
                }
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        // Paint the shell immediately — never block the whole page on network.
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
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 35),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back!',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            student?.name ??
                                (_loadingStudent ? 'Loading…' : 'Student'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            student?.regNumber ?? 'UOG-STUDENT',
                            style: const TextStyle(
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
              ),
              const SizedBox(height: 20),
              if (student?.assignedRouteId != null)
                _AssignedRouteCard(
                  student: student!,
                  routesStream: _routesStream,
                ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Quick Actions',
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
                childAspectRatio:
                    isDesktop ? 1.4 : (isTablet ? 1.15 : 1.05),
                children: [
                  DashboardCard(
                    title: 'Profile',
                    value: '',
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () => context.push('/personal-info'),
                  ),
                  DashboardCard(
                    title: 'Routes',
                    value: '',
                    icon: Icons.directions_bus_rounded,
                    color: const Color(0xFF0EA5E9),
                    onTap: () => context.push('/student-routes'),
                  ),
                  DashboardCard(
                    title: 'Schedule',
                    value: '',
                    icon: Icons.event_note_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push(
                      '/schedule',
                      extra: student?.assignedRouteId,
                    ),
                  ),
                  DashboardCard(
                    title: 'Live Track',
                    value: '',
                    icon: Icons.location_searching_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () =>
                        context.push('/live-tracking', extra: student),
                  ),
                  DashboardCard(
                    title: 'Notices',
                    value: '',
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => context.push('/notices'),
                  ),
                  DashboardCard(
                    title: 'Feedback',
                    value: '',
                    icon: Icons.rate_review_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/feedback'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bus schedules are subject to change during exam weeks. Please check notifications regularly.',
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
      ),
    );
  }
}

class _AssignedRouteCard extends StatelessWidget {
  final StudentModel student;
  final Stream<List<RouteModel>> routesStream;

  const _AssignedRouteCard({
    required this.student,
    required this.routesStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RouteModel>>(
      stream: routesStream,
      builder: (context, routeSnap) {
        final routes = routeSnap.data ?? [];
        RouteModel? route;
        if (student.assignedRouteId != null) {
          for (final r in routes) {
            if (r.id == student.assignedRouteId) {
              route = r;
              break;
            }
          }
        }
        final driverName = route?.displayDriverName ??
            student.assignedDriverName ??
            'Not Assigned';
        final driverPhone = (route?.driverPhone.isNotEmpty == true)
            ? route!.driverPhone
            : (student.assignedDriverPhone ?? '');
        final busNo = (route?.busNo.isNotEmpty == true)
            ? route!.busNo
            : (student.assignedBusCode ?? '');
        final driverId = route?.driverId ?? student.assignedDriverId;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Assigned Route',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.route, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Name',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          route?.routeName ??
                              student.assignedRouteName ??
                              'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (busNo.isNotEmpty)
                          Text(
                            'Bus $busNo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_pin, color: Colors.green),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Driver',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          driverName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (driverPhone.isNotEmpty)
                          Text(
                            driverPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (driverId != null && driverId.isNotEmpty)
                      _OnDutyChip(driverId: driverId),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Single-doc listener instead of streaming every driver.
class _OnDutyChip extends StatefulWidget {
  final String driverId;
  const _OnDutyChip({required this.driverId});

  @override
  State<_OnDutyChip> createState() => _OnDutyChipState();
}

class _OnDutyChipState extends State<_OnDutyChip> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    try {
      if (Firebase.apps.isNotEmpty) {
        _stream = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.driverId)
            .snapshots(includeMetadataChanges: false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final onDuty = snap.data?.data()?['isOnDuty'] == true;
        if (!onDuty) return const SizedBox.shrink();
        return const Chip(
          label: Text(
            'ON DUTY',
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: Colors.green,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    );
  }
}
