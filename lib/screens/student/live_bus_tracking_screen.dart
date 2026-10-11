import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_tracking_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/maps_launcher_service.dart';
import '../../utils/map_marker_helper.dart';

/// Live Bus Tracking — map widget is kept stable (no rebuild thrash).
class LiveBusTrackingScreen extends StatefulWidget {
  final StudentModel? student;

  const LiveBusTrackingScreen({super.key, this.student});

  @override
  State<LiveBusTrackingScreen> createState() => _LiveBusTrackingScreenState();
}

class _LiveBusTrackingScreenState extends State<LiveBusTrackingScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _studentIcon;
  bool _iconsReady = false;
  bool _started = false;
  bool _fittedOnce = false;
  String? _loadError;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _statusLabel = 'Waiting…';
  String _busNumber = '—';
  String _driverName = '—';
  String _routeName = '—';
  String _lastUpdated = '—';
  bool _isLive = false;
  String? _bannerError;

  static const _fallback = CameraPosition(
    target: LatLng(25.1450, 62.3600),
    zoom: 13.5,
  );

  LiveTrackingProvider? _tracker;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracker ??= context.read<LiveTrackingProvider>();
    _tracker!.addListener(_onTrackerChanged);
    if (_started) return;
    _started = true;
    _bootstrap();
  }

  Future<void> _loadIcons() async {
    try {
      final results = await Future.wait([
        MapMarkerHelper.createBusMarker(),
        MapMarkerHelper.createStudentMarker(),
      ]);
      if (!mounted) return;
      setState(() {
        _busIcon = results[0];
        _studentIcon = results[1];
        _iconsReady = true;
      });
      _syncFromTracker();
    } catch (_) {
      if (mounted) setState(() => _iconsReady = true);
    }
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
      if (mounted) _syncFromTracker();
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Failed to start tracking: $e');
    }
  }

  void _onTrackerChanged() {
    if (!mounted) return;
    _syncFromTracker();
  }

  void _syncFromTracker() {
    final tracker = _tracker;
    if (tracker == null || !_iconsReady) return;

    final markers = <Marker>{};
    final studentPos = tracker.studentLatLng;
    final busPos = tracker.busLatLng;
    final bus = tracker.busLocation;

    if (studentPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('student'),
          position: studentPos,
          icon: _studentIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'You'),
          zIndexInt: 2,
        ),
      );
    }

    if (busPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: busPos,
          rotation: bus?.heading ?? 0,
          flat: true,
          icon: _busIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: bus?.busNumber.isNotEmpty == true
                ? 'Bus ${bus!.busNumber}'
                : 'Live Bus',
          ),
          zIndexInt: 3,
        ),
      );
    }

    for (final stop in tracker.route?.stops ?? const []) {
      if (stop.lat == 0 && stop.lng == 0) continue;
      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.order}'),
          position: LatLng(stop.lat, stop.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: stop.stopName),
          zIndexInt: 1,
        ),
      );
    }

    final points = tracker.routePolylinePoints;
    final polylines = points.length < 2
        ? <Polyline>{}
        : {
            Polyline(
              polylineId: const PolylineId('assigned_route'),
              points: points,
              color: const Color(0xFF1565C0),
              width: 5,
            ),
          };

    final student = tracker.student;
    setState(() {
      _markers = markers;
      _polylines = polylines;
      _statusLabel = tracker.statusLabel;
      _isLive = tracker.isBusLive;
      _busNumber = bus?.busNumber.isNotEmpty == true
          ? bus!.busNumber
          : (student?.assignedBusCode ?? student?.assignedBusName ?? '—');
      _driverName = bus?.driverName.isNotEmpty == true
          ? bus!.driverName
          : (student?.assignedDriverName ?? '—');
      _routeName = bus?.routeName.isNotEmpty == true
          ? bus!.routeName
          : (tracker.route?.routeName ?? student?.assignedRouteName ?? '—');
      _lastUpdated = bus == null
          ? '—'
          : DateFormat('hh:mm:ss a').format(bus.lastUpdated);
      _bannerError = tracker.error;
    });

    if (!_fittedOnce &&
        (studentPos != null || busPos != null || points.isNotEmpty)) {
      _fittedOnce = true;
      _fitCamera(tracker);
    }
  }

  Future<void> _fitCamera(LiveTrackingProvider tracker) async {
    final controller = _mapController;
    if (controller == null) return;
    final points = <LatLng>[
      ...tracker.routePolylinePoints,
      if (tracker.studentLatLng != null) tracker.studentLatLng!,
      if (tracker.busLatLng != null) tracker.busLatLng!,
    ];
    if (points.isEmpty) return;
    try {
      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
        return;
      }
      double minLat = points.first.latitude, maxLat = points.first.latitude;
      double minLng = points.first.longitude, maxLng = points.first.longitude;
      for (final p in points) {
        minLat = p.latitude < minLat ? p.latitude : minLat;
        maxLat = p.latitude > maxLat ? p.latitude : maxLat;
        minLng = p.longitude < minLng ? p.longitude : minLng;
        maxLng = p.longitude > maxLng ? p.longitude : maxLng;
      }
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          80,
        ),
      );
    } catch (_) {
      // Ignore camera races while map is attaching.
    }
  }

  Future<void> _openInGoogleMaps() async {
    final tracker = _tracker;
    if (tracker == null) return;
    final bus = tracker.busLatLng;
    final student = tracker.studentLatLng;
    if (bus == null && student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No live coordinates yet.')),
      );
      return;
    }
    final ok = bus != null
        ? await MapsLauncherService.openBusTrackingInGoogleMaps(
            studentLat: student?.latitude,
            studentLng: student?.longitude,
            busLat: bus.latitude,
            busLng: bus.longitude,
            busLabel: _busNumber,
          )
        : await MapsLauncherService.openLocation(
            lat: student!.latitude,
            lng: student.longitude,
            label: 'My location',
          );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tracker?.removeListener(_onTrackerChanged);
    _tracker?.stopTracking();
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Bus Tracking')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_loadError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        actions: [
          IconButton(
            tooltip: 'Fit map',
            onPressed: () {
              if (_tracker != null) _fitCamera(_tracker!);
            },
            icon: const Icon(Icons.zoom_out_map),
          ),
          IconButton(
            tooltip: 'Refresh location',
            onPressed: () => _tracker?.refreshPermissions(),
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_iconsReady)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              // Stable key — do not recreate map on every GPS tick.
              key: const ValueKey('live_bus_map'),
              mapType: MapType.normal,
              initialCameraPosition: _fallback,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (c) {
                _mapController = c;
                if (_tracker != null) _fitCamera(_tracker!);
              },
            ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _InfoCard(
              statusLabel: _statusLabel,
              isLive: _isLive,
              lastUpdated: _lastUpdated,
              busNumber: _busNumber,
              driverName: _driverName,
              routeName: _routeName,
            ),
          ),
          if (_bannerError != null && _bannerError!.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 100,
              child: Material(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _bannerError!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton.extended(
            heroTag: 'open_gmaps',
            backgroundColor: const Color(0xFF34A853),
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.map),
            label: const Text('Open in Google Maps'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'fit_route',
            onPressed: () {
              if (_tracker != null) _fitCamera(_tracker!);
            },
            icon: const Icon(Icons.center_focus_strong),
            label: const Text('Fit route'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String statusLabel;
  final bool isLive;
  final String lastUpdated;
  final String busNumber;
  final String driverName;
  final String routeName;

  const _InfoCard({
    required this.statusLabel,
    required this.isLive,
    required this.lastUpdated,
    required this.busNumber,
    required this.driverName,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.green.shade50 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLive ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: isLive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLive ? Colors.green.shade800 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated $lastUpdated',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _row(Icons.directions_bus, 'Bus', busNumber),
            _row(Icons.person, 'Driver', driverName),
            _row(Icons.route, 'Route', routeName),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
