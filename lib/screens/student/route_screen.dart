import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/bus_route_card.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/student_model.dart';
import '../../core/constants/app_colors.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  bool _isProcessing = false;

  // Mock Route List
  final List<Map<String, dynamic>> _allRoutes = [
    {
      "busName": "Bus B",
      "busCode": "UOG-002",
      "status": BusStatus.delayed,
      "driverName": "Zahid Khan",
      "driverPhone": "03339876543",
      "startLocation": "Pishukan",
      "destination": "University Campus",
      "departureTime": "07:15 AM",
      "arrivalTime": "08:30 AM",
    },
    {
      "busName": "Bus C",
      "busCode": "UOG-003",
      "status": BusStatus.scheduled,
      "driverName": "Irfan Ali",
      "driverPhone": "03125554433",
      "startLocation": "East Bay",
      "destination": "University Campus",
      "departureTime": "08:00 AM",
      "arrivalTime": "08:45 AM",
    },
    {
      "busName": "Bus D",
      "busCode": "UOG-004",
      "status": BusStatus.scheduled,
      "driverName": "Sajid Baloch",
      "driverPhone": "03441112233",
      "startLocation": "Pasni Road",
      "destination": "University Campus",
      "departureTime": "06:45 AM",
      "arrivalTime": "08:00 AM",
    }
  ];

  Future<void> _showSelectionDialog(
    BuildContext context,
    StudentProvider provider,
    String studentUid,
    Map<String, dynamic> routeData,
    StudentModel? currentStudent,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Switch Main Route?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to select ${routeData['busName']} as your primary route?"),
            const SizedBox(height: 12),
            Text("Driver: ${routeData['driverName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Start: ${routeData['startLocation']}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePrimaryRoute(
                context,
                provider,
                studentUid,
                routeData['busName'],
                routeData['busCode'],
                routeData['driverName'],
                routeData['driverPhone'],
                routeData['startLocation'],
                routeData['departureTime'],
                routeData['arrivalTime'],
                currentStudent,
              );
            },
            child: const Text("Select Route"),
          ),
        ],
      ),
    );
  }

  Future<void> _showDriverDetails(BuildContext context, Map<String, dynamic> routeData) {
    final String phone = routeData['driverPhone'] ?? '';

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40), // Increased bottom padding to fix overflow
        child: SingleChildScrollView( // Added scroll view to ensure clickability on smaller screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Driver Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 24),
              _detailRow(Icons.person_outline, "Driver Name", routeData['driverName']),
              _detailRow(Icons.badge_outlined, "Driver ID", "DRV-${routeData['busCode'].split('-').last}"),
              _detailRow(Icons.directions_bus_outlined, "Bus Number", routeData['busCode']),
              _detailRow(Icons.route_outlined, "Route", "${routeData['startLocation']} → ${routeData['destination']}"),
              _detailRow(Icons.phone_outlined, "Contact", phone),
              _detailRow(Icons.verified_user_outlined, "Status", "Active", valueColor: Colors.green),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: phone.isEmpty ? null : () async {
                        final Uri url = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text("Call Driver"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: phone.isEmpty ? null : () async {
                        final Uri url = Uri.parse('sms:$phone');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Message"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRoute(
    BuildContext context,
    StudentProvider provider,
    String studentUid,
    StudentModel? currentStudent,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final updatedStudent = StudentModel(
        uid: studentUid,
        name: currentStudent?.name ?? "Student",
        email: currentStudent?.email ?? "",
        phone: currentStudent?.phone ?? "",
        role: currentStudent?.role ?? 'student',
        regNumber: currentStudent?.regNumber ?? "UOG-STU",
        fatherName: currentStudent?.fatherName ?? "",
        gender: currentStudent?.gender ?? "",
        dob: currentStudent?.dob ?? "",
        department: currentStudent?.department ?? "",
        semester: currentStudent?.semester ?? "1",
        profileImage: currentStudent?.profileImage ?? "",
        routeAddress: currentStudent?.routeAddress ?? "",
        rollNo: currentStudent?.rollNo ?? "0000",
        assignedRouteId: null,
        assignedRouteName: null,
        assignedBusId: null,
        assignedBusName: null,
        assignedBusCode: null,
        assignedDriverId: null,
        assignedDriverName: null,
        assignedDriverPhone: null,
        assignedDepartureTime: null,
        assignedArrivalTime: null,
        verificationStatus: currentStudent?.verificationStatus ?? 'approved',
      );

      await provider.updateStudent(updatedStudent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Route cancelled successfully"),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel route"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updatePrimaryRoute(
    BuildContext context,
    StudentProvider provider,
    String studentUid,
    String busName,
    String busCode,
    String driverName,
    String driverPhone,
    String startLoc,
    String depTime,
    String arrTime,
    StudentModel? currentStudent,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final updatedStudent = StudentModel(
        uid: studentUid,
        name: currentStudent?.name ?? "Student",
        email: currentStudent?.email ?? "",
        phone: currentStudent?.phone ?? "",
        role: currentStudent?.role ?? 'student',
        regNumber: currentStudent?.regNumber ?? "UOG-STU",
        fatherName: currentStudent?.fatherName ?? "",
        gender: currentStudent?.gender ?? "",
        dob: currentStudent?.dob ?? "",
        department: currentStudent?.department ?? "",
        semester: currentStudent?.semester ?? "1",
        profileImage: currentStudent?.profileImage ?? "",
        routeAddress: currentStudent?.routeAddress ?? startLoc,
        rollNo: currentStudent?.rollNo ?? "0000",
        assignedRouteId: busCode,
        assignedRouteName: busName,
        assignedBusId: busCode,
        assignedBusName: busName,
        assignedBusCode: busCode,
        assignedDriverId: 'driver_$busCode',
        assignedDriverName: driverName,
        assignedDriverPhone: driverPhone,
        assignedDepartureTime: depTime,
        assignedArrivalTime: arrTime,
        verificationStatus: currentStudent?.verificationStatus ?? 'approved',
      );

      await provider.updateStudent(updatedStudent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully joined $busName route"),
            backgroundColor: AppColors.success,
          ),
        );
        // Directly move to live tracking section
        context.push('/live-tracking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update route"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Routes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder(
            future: studentProvider.getStudent(authProvider.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final student = snapshot.data;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (student != null && student.assignedRouteId != null) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        "Current Assigned Bus",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    BusRouteCard(
                      busName: student.assignedBusName ?? "Bus A",
                      busCode: student.assignedBusCode ?? "UOG-001",
                      status: BusStatus.inTransit,
                      isPrimary: true,
                      driverName: student.assignedDriverName ?? "Ahmed K.",
                      driverPhone: student.assignedDriverPhone ?? "03001234567",
                      startLocation: student.routeAddress.isNotEmpty ? student.routeAddress : "Gwadar City",
                      destination: "University Campus",
                      departureTime: student.assignedDepartureTime ?? "07:30 AM",
                      arrivalTime: student.assignedArrivalTime ?? "08:15 AM",
                      currentLocation: "Marine Drive",
                      onCall: () {},
                      onChat: () {},
                      onCancel: () => _cancelRoute(context, studentProvider, authProvider.uid!, student),
                      onShowDriverDetails: () => _showDriverDetails(context, {
                        'busName': student.assignedBusName ?? "Bus A",
                        'busCode': student.assignedBusCode ?? "UOG-001",
                        'driverName': student.assignedDriverName ?? "Ahmed K.",
                        'driverPhone': student.assignedDriverPhone ?? "03001234567",
                        'startLocation': student.routeAddress.isNotEmpty ? student.routeAddress : "Gwadar City",
                        'destination': "University Campus",
                      }),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "Alternative Routes",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  ..._allRoutes.map((routeData) {
                    // Don't show if it's already assigned
                    if (student?.assignedBusCode == routeData['busCode']) return const SizedBox.shrink();
                    
                    return BusRouteCard(
                      busName: routeData['busName'],
                      busCode: routeData['busCode'],
                      status: routeData['status'],
                      driverName: routeData['driverName'],
                      driverPhone: routeData['driverPhone'],
                      startLocation: routeData['startLocation'],
                      destination: routeData['destination'],
                      departureTime: routeData['departureTime'],
                      arrivalTime: routeData['arrivalTime'],
                      onCall: () {},
                      onChat: () {},
                      onSelect: authProvider.uid == null ? null : () => _showSelectionDialog(
                        context, studentProvider, authProvider.uid!, routeData, student
                      ),
                      onShowDriverDetails: () => _showDriverDetails(context, routeData),
                    );
                  }),
                ],
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
