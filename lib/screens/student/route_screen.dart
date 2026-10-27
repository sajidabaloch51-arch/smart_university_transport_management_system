import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bus_route_card.dart';
import '../../widgets/async_state_view.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../models/student_model.dart';
import '../../models/route_model.dart';
import '../../core/constants/app_colors.dart';
import '../../utils/phone_launcher.dart';
import '../../services/live_firestore.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  bool _isProcessing = false;
  /// Cached public phones by driverId (avoids one query per rebuild).
  final Map<String, String> _phoneByDriverId = {};
  late Stream<List<RouteModel>> _routesStream;
  StudentModel? _student;
  List<RouteModel> _routes = const [];
  bool _phonesPrefetchStarted = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final students = context.read<StudentProvider>();
    final routes = context.read<RouteProvider>();
    _routesStream = routes.streamRoutes();
    _student = students.peekStudent(auth.uid ?? '');
    _routes = routes.cachedRoutes;
    LiveFirestore.log(
      'MyRoutes.init',
      collection: 'routes',
      extra: 'uid=${auth.uid} cachedRoutes=${_routes.length}',
    );

    // ignore: discarded_futures
    _bootstrap(auth.uid ?? '', students, routes);
  }

  void _retryRoutes() {
    final routes = context.read<RouteProvider>();
    routes.restartRoutesStream();
    setState(() {
      _phonesPrefetchStarted = false;
      _routesStream = routes.streamRoutes();
    });
  }

  Future<void> _bootstrap(
    String uid,
    StudentProvider students,
    RouteProvider routes,
  ) async {
    final results = await Future.wait<Object?>([
      students.getStudent(uid),
      routes.loadRoutesFromCache(),
    ]);
    if (!mounted) return;
    final student = results[0] as StudentModel?;
    final cachedRoutes = results[1] as List<RouteModel>;
    setState(() {
      if (student != null) _student = student;
      if (cachedRoutes.isNotEmpty) _routes = cachedRoutes;
    });
  }

  Map<String, dynamic> _routeToMap(RouteModel route) {
    final cachedPhone = route.driverId == null
        ? ''
        : (_phoneByDriverId[route.driverId!] ?? '');
    final phone = route.driverPhone.trim().isNotEmpty
        ? route.driverPhone.trim()
        : cachedPhone;
    return {
      'busName': route.routeName,
      'busCode': route.displayBusCode,
      'status': BusStatus.scheduled,
      'driverName': route.displayDriverName,
      'driverPhone': phone,
      'driverId': route.driverId,
      'startLocation': route.cardStartLabel,
      'destination': route.cardEndLabel,
      'departureTime': route.cardDepartureTime.isEmpty
          ? '—'
          : route.cardDepartureTime,
      'arrivalTime': route.cardArrivalTime.isEmpty
          ? (route.cardDuration.isEmpty ? '—' : route.cardDuration)
          : route.cardArrivalTime,
      'estimatedTime': route.cardDuration,
      'routeId': route.id,
      'hasDriver': route.hasAssignedDriver,
    };
  }

  Future<void> _prefetchPhones(List<RouteModel> routes) async {
    if (_phonesPrefetchStarted || Firebase.apps.isEmpty) return;
    final missing = <String>{};
    for (final r in routes) {
      if (!r.hasAssignedDriver) continue;
      final id = r.driverId!;
      if (r.driverPhone.trim().isNotEmpty) {
        _phoneByDriverId[id] = r.driverPhone.trim();
        continue;
      }
      if (!_phoneByDriverId.containsKey(id)) missing.add(id);
    }
    if (missing.isEmpty) return;
    _phonesPrefetchStarted = true;

    final db = FirebaseFirestore.instance;
    await Future.wait(missing.map((id) async {
      try {
        String phone = '';
        try {
          final cached = await db
              .collection('driverPublic')
              .doc(id)
              .get(const GetOptions(source: Source.cache))
              .timeout(const Duration(milliseconds: 300));
          phone = cached.data()?['phone']?.toString().trim() ?? '';
        } catch (_) {}
        if (phone.isEmpty) {
          final pub = await db
              .collection('driverPublic')
              .doc(id)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 3));
          phone = pub.data()?['phone']?.toString().trim() ?? '';
        }
        if (phone.isEmpty) {
          final user = await db
              .collection('users')
              .doc(id)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 3));
          phone = user.data()?['phone']?.toString().trim() ?? '';
        }
        _phoneByDriverId[id] = phone;
      } catch (e) {
        debugPrint('prefetch phone for $id failed: $e');
        _phoneByDriverId[id] = '';
      }
    }));
    if (mounted) setState(() {});
  }

  Future<void> _launchTel(String phone) =>
      PhoneLauncher.call(phone, context: context);

  Future<void> _launchSms(String phone) =>
      PhoneLauncher.sms(phone, context: context);

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
        title: const Text('Switch Main Route?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to select ${routeData['busName']} as your primary route?',
            ),
            const SizedBox(height: 12),
            Text(
              'Driver: ${routeData['driverName']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Start: ${routeData['startLocation']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePrimaryRoute(
                context,
                provider,
                studentUid,
                routeData,
                currentStudent,
              );
            },
            child: const Text('Select Route'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDriverDetails(
    BuildContext context,
    Map<String, dynamic> routeData,
  ) {
    final String phone = (routeData['driverPhone'] ?? '').toString();
    final hasDriver = routeData['hasDriver'] == true ||
        ((routeData['driverName'] ?? '') != 'Not Assigned' &&
            (routeData['driverName'] ?? '').toString().isNotEmpty);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: SingleChildScrollView(
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
                'Driver Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              _detailRow(
                Icons.person_outline,
                'Driver Name',
                hasDriver
                    ? (routeData['driverName'] ?? 'Not Assigned')
                    : 'Not Assigned',
              ),
              _detailRow(
                Icons.directions_bus_outlined,
                'Bus Number',
                routeData['busCode'] ?? '—',
              ),
              _detailRow(
                Icons.route_outlined,
                'Route',
                '${routeData['startLocation']} → ${routeData['destination']}',
              ),
              _detailRow(
                Icons.phone_outlined,
                'Contact',
                phone.isEmpty ? '—' : phone,
              ),
              _detailRow(
                Icons.verified_user_outlined,
                'Status',
                hasDriver ? 'Assigned' : 'Unassigned',
                valueColor: hasDriver ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !hasDriver
                          ? null
                          : () async {
                              final p = phone.isNotEmpty
                                  ? phone
                                  : await _resolvePhone(routeData);
                              if (!context.mounted) return;
                              await PhoneLauncher.call(p, context: context);
                            },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !hasDriver
                          ? null
                          : () async {
                              final p = phone.isNotEmpty
                                  ? phone
                                  : await _resolvePhone(routeData);
                              if (!context.mounted) return;
                              await PhoneLauncher.sms(p, context: context);
                            },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
        name: currentStudent?.name ?? 'Student',
        email: currentStudent?.email ?? '',
        phone: currentStudent?.phone ?? '',
        role: currentStudent?.role ?? 'student',
        regNumber: currentStudent?.regNumber ?? 'UOG-STU',
        fatherName: currentStudent?.fatherName ?? '',
        gender: currentStudent?.gender ?? '',
        dob: currentStudent?.dob ?? '',
        department: currentStudent?.department ?? '',
        semester: currentStudent?.semester ?? '1',
        profileImage: currentStudent?.profileImage ?? '',
        routeAddress: currentStudent?.routeAddress ?? '',
        rollNo: currentStudent?.rollNo ?? '0000',
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
            content: Text('Route cancelled successfully'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel route'),
            backgroundColor: AppColors.error,
          ),
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
    Map<String, dynamic> routeData,
    StudentModel? currentStudent,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final routeId = routeData['routeId'] as String?;
      final hasDriver = routeData['hasDriver'] == true;
      final driverName = (routeData['driverName'] ?? 'Not Assigned').toString();
      final driverPhone = (routeData['driverPhone'] ?? '').toString();
      final driverId = routeData['driverId'] as String?;

      final updatedStudent = StudentModel(
        uid: studentUid,
        name: currentStudent?.name ?? 'Student',
        email: currentStudent?.email ?? '',
        phone: currentStudent?.phone ?? '',
        role: currentStudent?.role ?? 'student',
        regNumber: currentStudent?.regNumber ?? '',
        fatherName: currentStudent?.fatherName ?? '',
        gender: currentStudent?.gender ?? '',
        dob: currentStudent?.dob ?? '',
        department: currentStudent?.department ?? '',
        semester: currentStudent?.semester ?? '1',
        profileImage: currentStudent?.profileImage ?? '',
        routeAddress: currentStudent?.routeAddress.isNotEmpty == true
            ? currentStudent!.routeAddress
            : (routeData['startLocation'] ?? ''),
        rollNo: currentStudent?.rollNo ?? '',
        assignedRouteId: routeId,
        assignedRouteName: routeData['busName'] as String?,
        assignedBusId: routeData['busCode'] as String?,
        assignedBusName: routeData['busName'] as String?,
        assignedBusCode: routeData['busCode'] as String?,
        assignedDriverId: hasDriver ? driverId : null,
        assignedDriverName: hasDriver ? driverName : null,
        assignedDriverPhone: hasDriver ? driverPhone : null,
        assignedDepartureTime: routeData['departureTime'] as String?,
        assignedArrivalTime: routeData['arrivalTime'] as String?,
        verificationStatus: currentStudent?.verificationStatus ?? 'pending',
      );

      await provider.updateStudent(updatedStudent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${routeData['busName']} route'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/live-tracking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update route'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String> _resolvePhone(Map<String, dynamic> routeData) async {
    var phone = (routeData['driverPhone'] ?? '').toString().trim();
    if (phone.isNotEmpty) return phone;
    final driverId = routeData['driverId']?.toString();
    if (driverId == null || driverId.isEmpty) return '';
    if (_phoneByDriverId.containsKey(driverId) &&
        _phoneByDriverId[driverId]!.isNotEmpty) {
      return _phoneByDriverId[driverId]!;
    }
    if (Firebase.apps.isEmpty) return '';
    try {
      final db = FirebaseFirestore.instance;
      final pub = await db.collection('driverPublic').doc(driverId).get();
      phone = pub.data()?['phone']?.toString().trim() ?? '';
      if (phone.isEmpty) {
        final user = await db.collection('users').doc(driverId).get();
        phone = user.data()?['phone']?.toString().trim() ?? '';
      }
      _phoneByDriverId[driverId] = phone;
      if (mounted) setState(() {});
    } catch (_) {}
    return phone;
  }

  Widget _buildRouteCard({
    required Map<String, dynamic> routeData,
    required bool isPrimary,
    required StudentProvider studentProvider,
    required AuthProvider authProvider,
    required StudentModel? student,
  }) {
    final phone = (routeData['driverPhone'] ?? '').toString();
    final hasDriver = routeData['hasDriver'] == true;
    // Enable whenever a driver is linked; resolve phone on tap if needed.
    final canContact = hasDriver || phone.trim().isNotEmpty;

    return BusRouteCard(
      busName: routeData['busName'] ?? 'Route',
      busCode: routeData['busCode'] ?? '—',
      status: routeData['status'] as BusStatus? ?? BusStatus.scheduled,
      isPrimary: isPrimary,
      driverName: routeData['driverName'] ?? 'Not Assigned',
      driverPhone: phone,
      startLocation: routeData['startLocation'] ?? '—',
      destination: routeData['destination'] ?? '—',
      departureTime: routeData['departureTime'] ?? '—',
      arrivalTime: routeData['arrivalTime'] ?? '—',
      onCall: canContact
          ? () async {
              final p = await _resolvePhone(routeData);
              if (!mounted) return;
              await _launchTel(p);
            }
          : null,
      onChat: canContact
          ? () async {
              final p = await _resolvePhone(routeData);
              if (!mounted) return;
              await _launchSms(p);
            }
          : null,
      onCancel: isPrimary && authProvider.uid != null
          ? () => _cancelRoute(
                context,
                studentProvider,
                authProvider.uid!,
                student,
              )
          : null,
      onSelect: !isPrimary && authProvider.uid != null
          ? () => _showSelectionDialog(
                context,
                studentProvider,
                authProvider.uid!,
                routeData,
                student,
              )
          : null,
      onShowDriverDetails: () => _showDriverDetails(context, routeData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.read<StudentProvider>();
    final authProvider = context.read<AuthProvider>();

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          AsyncStateView<List<RouteModel>>(
            stream: _routesStream,
            initialData: _routes.isEmpty ? null : _routes,
            onRetry: _retryRoutes,
            isEmpty: (list) =>
                list.where((r) => r.isActive).isEmpty &&
                _student?.assignedRouteId == null,
            emptyMessage: 'No routes available yet.',
            emptySubtitle:
                'Ask the Transport Admin to add routes, or use Seed sample data.',
            builder: (context, liveRoutes) {
              _routes = liveRoutes;
              final allRoutes =
                  liveRoutes.where((r) => r.isActive).toList(growable: false);
              final student = _student;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _prefetchPhones(allRoutes);
              });

              RouteModel? primaryRoute;
              final assignedId = student?.assignedRouteId;
              if (assignedId != null) {
                for (final r in allRoutes) {
                  if (r.id == assignedId) {
                    primaryRoute = r;
                    break;
                  }
                }
              }

              final available = assignedId == null
                  ? allRoutes
                  : allRoutes.where((r) => r.id != assignedId).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (assignedId != null) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Current Assigned Bus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _buildRouteCard(
                      routeData: primaryRoute != null
                          ? _routeToMap(primaryRoute)
                          : {
                              'busName': student?.assignedRouteName ??
                                  student?.assignedBusName ??
                                  'Assigned Route',
                              'busCode': student?.assignedBusCode ?? '—',
                              'status': BusStatus.scheduled,
                              'driverName':
                                  student?.assignedDriverName ?? 'Not Assigned',
                              'driverPhone':
                                  student?.assignedDriverPhone ?? '',
                              'driverId': student?.assignedDriverId,
                              'startLocation':
                                  (student?.routeAddress.isNotEmpty == true)
                                      ? student!.routeAddress
                                      : '—',
                              'destination': 'University Campus',
                              'departureTime':
                                  student?.assignedDepartureTime ?? '',
                              'arrivalTime':
                                  student?.assignedArrivalTime ?? '',
                              'routeId': assignedId,
                              'hasDriver':
                                  student?.assignedDriverId != null &&
                                      student!.assignedDriverId!.isNotEmpty,
                            },
                      isPrimary: true,
                      studentProvider: studentProvider,
                      authProvider: authProvider,
                      student: student,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Available Routes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (available.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No other routes available right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...available.map((route) {
                      return _buildRouteCard(
                        routeData: _routeToMap(route),
                        isPrimary: false,
                        studentProvider: studentProvider,
                        authProvider: authProvider,
                        student: student,
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
