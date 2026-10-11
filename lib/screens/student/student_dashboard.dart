import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/driver_provider.dart';
import '../../models/student_model.dart';
import '../../models/driver_model.dart';

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

    final authProvider = Provider.of<AuthProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use Logout button to exit session'), duration: Duration(seconds: 1)),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Student Portal"),
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
        body: FutureBuilder<StudentModel?>(
          future: studentProvider.getStudent(authProvider.uid ?? ''),
          builder: (context, snapshot) {
            final student = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
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
                                "Welcome back!",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              Text(
                                student?.name ?? "Student",
                                style: const TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white,
                                  letterSpacing: 0.5
                                ),
                              ),
                              Text(
                                student?.regNumber ?? "UOG-STUDENT", 
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Assigned Route & Driver Section
                  if (student?.assignedRouteId != null)
                    _buildRouteInfoCard(context, student!, driverProvider),

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
                        onTap: () => context.push('/schedule', extra: student?.assignedRouteId),
                      ),
                      DashboardCard(
                        title: 'Live Tracking', 
                        value: '', 
                        icon: Icons.location_searching_rounded, 
                        color: const Color(0xFF10B981), // Emerald
                        onTap: () => context.push('/live-tracking', extra: student),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(BuildContext context, StudentModel student, DriverProvider driverProvider) {
    return StreamBuilder<List<DriverModel>>(
      stream: driverProvider.streamDrivers(),
      builder: (context, snapshot) {
        final drivers = snapshot.data ?? [];
        final assignedDriver = drivers.firstWhere(
          (d) => d.assignedRouteId == student.assignedRouteId,
          orElse: () => DriverModel(
            uid: '', name: 'Not Assigned', email: '', phone: '', role: 'driver', 
            driverId: '', licenseNumber: '', profileImg: '', assignedBusId: '', assignedBusNumber: '', 
            assignedRouteId: '', assignedRouteName: '', isOnDuty: false
          ),
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Assigned Route",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.route, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Route Name", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(student.assignedRouteName ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text("Assigned Driver", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(assignedDriver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (assignedDriver.uid.isNotEmpty)
                          Text(assignedDriver.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    if (assignedDriver.isOnDuty)
                      const Chip(
                        label: Text("ON DUTY", style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
