import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_tracking_provider.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/map_marker_helper.dart';
import '../../widgets/osm_map_view.dart';

/// Student Live Bus Tracking — OpenStreetMap + Firestore GPS streams.
class LiveBusTrackingScreen extends StatefulWidget {
  final StudentModel? student;

  const LiveBusTrackingScreen({super.key, this.student});

  @override
  State<LiveBusTrackingScreen> createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen> {
  bool _started = false;
  String? _loadError;
  LiveTrackingProvider? _tracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracker ??= context.read<LiveTrackingProvider>();
    if (_started) return;
    _started = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      StudentModel? student = widget.student;
      student ??= await context.read<StudentProvider>().getStudent(
            context.read<AuthProvider>().uid ?? '',
          );
      if (!mounted) return;
      if (student == null) {
        setState(() {
          _loadError =
              'Student profile not found. Please login again or contact admin.';
        });
        return;
      }
      await _tracker!.startTracking(student);
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Failed to start tracking: $e');
    }
  }

  @override
  void dispose() {
    _tracker?.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Bus Tracking'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_loadError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Consumer<LiveTrackingProvider>(
      builder: (context, tracker, _) {
        final last = tracker.gps?.updatedAt ?? tracker.trip?.updatedAt;
        final lastLabel = last == null
            ? '—'
            : DateFormat('dd MMM, hh:mm a').format(last.toLocal());

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Bus Tracking'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              _InfoBar(
                status: tracker.statusLabel,
                isLive: tracker.isBusLive,
                busNumber: tracker.busNumber,
                routeName: tracker.routeName,
                driverName: tracker.driverName,
                lastUpdated: lastLabel,
                start: tracker.route?.cardStartLabel ?? '—',
                end: tracker.route?.cardEndLabel ?? '—',
              ),
              if (tracker.error != null)
                Material(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      tracker.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ),
              Expanded(
                child: tracker.loading
                    ? const Center(child: CircularProgressIndicator())
                    : tracker.trip == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Bus is not currently active.\n'
                                'When the driver starts a trip, the live location will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          )
                        : OsmMapView(
                            busLocation: tracker.busLatLng,
                            userLocation: tracker.studentLatLng,
                            routePoints:
                                MapMarkerHelper.routePolyline(tracker.route),
                            stops: MapMarkerHelper.stopMarkers(tracker.route),
                            busLabel: tracker.busNumber,
                            followBus: tracker.isBusLive,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoBar extends StatelessWidget {
  final String status;
  final bool isLive;
  final String busNumber;
  final String routeName;
  final String driverName;
  final String lastUpdated;
  final String start;
  final String end;

  const _InfoBar({
    required this.status,
    required this.isLive,
    required this.busNumber,
    required this.routeName,
    required this.driverName,
    required this.lastUpdated,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.green.shade50 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isLive ? Colors.green.shade800 : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated $lastUpdated',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Bus $busNumber · $routeName',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text('Driver: $driverName',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            Text('$start → $end',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
