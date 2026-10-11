import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_live_location_model.dart';
import '../models/route_model.dart';
import '../models/student_model.dart';
import '../services/location_service.dart';
import '../services/realtime_location_service.dart';

/// Student-side live bus tracking (throttled to avoid UI/map crashes).
class LiveTrackingProvider extends ChangeNotifier {
  final RealtimeLocationService _realtime = RealtimeLocationService();
  final LocationService _locationService = LocationService();

  StreamSubscription<BusLiveLocationModel?>? _busSub;
  StreamSubscription<Position>? _studentSub;
  Timer? _notifyThrottle;

  StudentModel? _student;
  RouteModel? _route;
  BusLiveLocationModel? _busLocation;
  LatLng? _studentLatLng;
  String? _error;
  bool _loading = false;
  bool _permissionGranted = false;
  bool _disposed = false;
  bool _dirty = false;

  StudentModel? get student => _student;
  RouteModel? get route => _route;
  BusLiveLocationModel? get busLocation => _busLocation;
  LatLng? get studentLatLng => _studentLatLng;
  LatLng? get busLatLng => _busLocation == null
      ? null
      : LatLng(_busLocation!.lat, _busLocation!.lng);
  String? get error => _error;
  bool get loading => _loading;
  bool get permissionGranted => _permissionGranted;

  String get statusLabel {
    if (_busLocation == null) return 'Waiting for bus…';
    return _busLocation!.isLive ? 'Live' : 'Offline';
  }

  bool get isBusLive => _busLocation?.isLive ?? false;

  Future<void> startTracking(StudentModel student) async {
    stopTracking();
    _disposed = false;
    _student = student;
    _error = null;
    _loading = true;
    _safeNotify();

    try {
      await _ensurePermissions();
      await _loadRoute(student.assignedRouteId);
      _listenToStudentLocation();
      _listenToBus(student.assignedDriverId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  Future<void> _ensurePermissions() async {
    try {
      _permissionGranted = await _locationService.checkPermissions();
      if (!_permissionGranted) {
        _error =
            'Location permission is required to show your position on the map.';
      }
    } catch (e) {
      _permissionGranted = false;
      _error = 'Unable to access location services: $e';
    }
  }

  Future<void> _loadRoute(String? routeId) async {
    if (routeId == null || routeId.isEmpty || Firebase.apps.isEmpty) {
      _route = null;
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .get()
          .timeout(const Duration(seconds: 8));
      if (doc.exists && doc.data() != null) {
        _route = RouteModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      // Firestore may be missing — keep app running with offline/local data.
      debugPrint('Failed to load route (Firestore unavailable?): $e');
      _error ??=
          'Cloud database unavailable. Create Firestore for project sutms-uog.';
    }
  }

  void _listenToStudentLocation() {
    _studentSub?.cancel();
    if (!_permissionGranted) return;

    _locationService.getCurrentLocation().then((pos) {
      if (_disposed) return;
      _studentLatLng = LatLng(pos.latitude, pos.longitude);
      _safeNotify();
    }).catchError((e) {
      debugPrint('getCurrentLocation failed: $e');
    });

    // Less frequent updates — avoids map widget thrashing on Realme devices.
    _studentSub = _locationService
        .getPositionStream(distanceFilterMeters: 25)
        .listen((pos) {
      if (_disposed) return;
      _studentLatLng = LatLng(pos.latitude, pos.longitude);
      _throttledNotify();
    }, onError: (e) {
      debugPrint('student position stream error: $e');
    });
  }

  void _listenToBus(String? driverId) {
    _busSub?.cancel();
    if (driverId == null || driverId.isEmpty) {
      _error = (_error == null || _error!.isEmpty)
          ? 'No driver assigned to your route yet.'
          : _error;
      _safeNotify();
      return;
    }

    _busSub = _realtime.watchDriverLocation(driverId).listen((loc) {
      if (_disposed) return;
      _busLocation = loc;
      _throttledNotify();
    }, onError: (e) {
      if (_disposed) return;
      _error = 'Live bus sync failed: $e';
      _safeNotify();
    });
  }

  /// Coalesce rapid GPS/RTDB updates into ~500ms UI refreshes.
  void _throttledNotify() {
    _dirty = true;
    if (_notifyThrottle?.isActive == true) return;
    _notifyThrottle = Timer(const Duration(milliseconds: 500), () {
      if (_disposed || !_dirty) return;
      _dirty = false;
      _safeNotify();
    });
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  List<LatLng> get routePolylinePoints {
    if (_route == null) return [];
    final stops = [..._route!.stops]..sort((a, b) => a.order.compareTo(b.order));
    return stops
        .where((s) => s.lat != 0.0 || s.lng != 0.0)
        .map((s) => LatLng(s.lat, s.lng))
        .toList();
  }

  Future<void> refreshPermissions() async {
    await _ensurePermissions();
    if (_permissionGranted && _student != null) {
      _listenToStudentLocation();
    }
    _safeNotify();
  }

  void stopTracking() {
    _busSub?.cancel();
    _studentSub?.cancel();
    _notifyThrottle?.cancel();
    _busSub = null;
    _studentSub = null;
    _notifyThrottle = null;
    _busLocation = null;
    // Keep last student lat/lng for faster reopen; clear on dispose.
  }

  @override
  void dispose() {
    _disposed = true;
    stopTracking();
    _studentLatLng = null;
    super.dispose();
  }
}
