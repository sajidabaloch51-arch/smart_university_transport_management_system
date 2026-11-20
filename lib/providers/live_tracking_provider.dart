import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/gps_location_model.dart';
import '../models/route_model.dart';
import '../models/student_model.dart';
import '../models/trip_model.dart';
import '../services/location_service.dart';
import '../services/trip_tracking_service.dart';

/// Student-side live bus tracking via Firestore trips + gps_locations.
class LiveTrackingProvider extends ChangeNotifier {
  final TripTrackingService _trips = TripTrackingService();
  final LocationService _locationService = LocationService();

  StreamSubscription<TripModel?>? _tripSub;
  StreamSubscription<GpsLocationModel?>? _gpsSub;
  StreamSubscription<Position>? _studentSub;
  Timer? _notifyThrottle;
  Timer? _agoTicker;

  StudentModel? _student;
  RouteModel? _route;
  TripModel? _trip;
  GpsLocationModel? _gps;
  LatLng? _studentLatLng;
  String? _error;
  bool _loading = false;
  bool _permissionGranted = false;
  bool _disposed = false;
  bool _dirty = false;

  StudentModel? get student => _student;
  RouteModel? get route => _route;
  TripModel? get trip => _trip;
  GpsLocationModel? get gps => _gps;
  LatLng? get studentLatLng => _studentLatLng;
  LatLng? get busLatLng {
    final g = _gps;
    if (g == null || !g.hasValidCoords) {
      final t = _trip;
      if (t?.lastLat != null && t?.lastLng != null) {
        return LatLng(t!.lastLat!, t.lastLng!);
      }
      return null;
    }
    return LatLng(g.latitude, g.longitude);
  }

  String? get error => _error;
  bool get loading => _loading;
  bool get permissionGranted => _permissionGranted;
  bool get isBusLive =>
      (_gps?.isLive ?? false) ||
      (_trip?.isActive == true && busLatLng != null && !_isLocationDelayed);

  bool get _isLocationDelayed {
    if (_trip?.isActive != true || busLatLng == null) return false;
    final updated = _gps?.updatedAt ?? _trip?.updatedAt;
    if (updated == null) return false;
    return DateTime.now().toUtc().difference(updated.toUtc()).inMinutes >= 2;
  }

  bool get hasAssignment {
    final s = _student;
    if (s == null) return false;
    final routeId = (s.assignedRouteId ?? '').trim();
    final busId = (s.assignedBusId ?? '').trim();
    final busCode = (s.assignedBusCode ?? s.assignedBusName ?? '').trim();
    return routeId.isNotEmpty || busId.isNotEmpty || busCode.isNotEmpty;
  }

  String get statusLabel {
    if (!hasAssignment) return 'Select a route first';
    if (_trip == null) return 'Bus is not currently active';
    if (!_trip!.isActive) return 'Trip ended';
    if (busLatLng == null) return "Waiting for the driver's location...";
    if (_isLocationDelayed) return 'Location delayed';
    if (_gps?.isLive == true || busLatLng != null) return 'Live';
    return "Waiting for the driver's location...";
  }

  String get updatedAgoLabel {
    final last = _gps?.updatedAt ?? _trip?.updatedAt;
    if (last == null) return '—';
    final secs = DateTime.now().toUtc().difference(last.toUtc()).inSeconds;
    if (secs < 8) return 'just now';
    if (secs < 60) return '${secs}s ago';
    final mins = secs ~/ 60;
    if (mins < 60) return '${mins}m ago';
    return '${mins ~/ 60}h ago';
  }

  String get busNumber =>
      _trip?.busNumber.isNotEmpty == true
          ? _trip!.busNumber
          : (_student?.assignedBusCode ??
              _student?.assignedBusName ??
              _route?.busNo ??
              '—');

  String get driverName =>
      _trip?.driverName.isNotEmpty == true
          ? _trip!.driverName
          : (_student?.assignedDriverName ?? _route?.displayDriverName ?? '—');

  String get routeName =>
      _trip?.routeName.isNotEmpty == true
          ? _trip!.routeName
          : (_student?.assignedRouteName ?? _route?.routeName ?? '—');

  /// Test-only: seed assignment / trip / GPS without hitting Firestore.
  @visibleForTesting
  void seedForUiTest({
    StudentModel? student,
    TripModel? trip,
    GpsLocationModel? gps,
  }) {
    _student = student;
    _trip = trip;
    _gps = gps;
  }

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
      _listenForActiveTrip(student);
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
            'Location permission is optional for viewing the bus, but needed to show your position.';
      }
    } catch (e) {
      _permissionGranted = false;
      _error = 'Unable to access location services: $e';
    }
  }

  Future<void> _loadRoute(String? routeId) async {
    if (routeId == null || routeId.isEmpty || Firebase.apps.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .get();
      if (doc.exists && doc.data() != null) {
        _route = RouteModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      debugPrint('load route failed: $e');
    }
  }

  void _listenForActiveTrip(StudentModel student) {
    _tripSub?.cancel();
    _gpsSub?.cancel();

    final busId = student.assignedBusId?.trim() ?? '';
    final busNumber =
        (student.assignedBusCode ?? student.assignedBusName ?? '').trim();
    final routeId = student.assignedRouteId?.trim() ?? _route?.id ?? '';
    final driverId = student.assignedDriverId?.trim() ??
        _route?.driverId?.trim() ??
        '';

    if (routeId.isEmpty &&
        busId.isEmpty &&
        busNumber.isEmpty &&
        driverId.isEmpty) {
      _trip = null;
      _gps = null;
      _error = 'No bus or route assigned. Contact Admin.';
      _safeNotify();
      return;
    }

    // Prefer routeId, then busId/busNumber (case-insensitive), then driverId.
    // Uses ACTIVE trips list + Dart match — no composite index required.
    final stream = _trips.watchActiveTripMatching(
      routeId: routeId,
      busId: busId,
      busNumber: busNumber,
      driverId: driverId,
    );

    _tripSub = stream.listen((trip) {
      _trip = trip;
      _gpsSub?.cancel();
      if (trip == null) {
        _gps = null;
        _agoTicker?.cancel();
        _agoTicker = null;
        _safeNotify();
        return;
      }
      _agoTicker?.cancel();
      _agoTicker = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_disposed) return;
        _safeNotify();
      });
      _gpsSub = _trips.watchTripGps(trip.id).listen((gps) {
        _gps = gps;
        _safeNotify();
      }, onError: (e) {
        _error = _friendlyStreamError(e, 'GPS');
        _safeNotify();
      });
      _safeNotify();
    }, onError: (e) {
      _error = _friendlyStreamError(e, 'Trip');
      _safeNotify();
    });
  }

  String _friendlyStreamError(Object e, String label) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission-denied') || s.contains('permission_denied')) {
      return "$label access denied. Log out and sign in again, or ask Admin.";
    }
    if (s.contains('unavailable') ||
        s.contains('network') ||
        s.contains('socket')) {
      return "Can't reach the server for $label updates. Check your connection.";
    }
    return '$label stream error: $e';
  }

  void _listenToStudentLocation() {
    if (!_permissionGranted) return;
    _studentSub?.cancel();
    _studentSub = _locationService.getPositionStream().listen((pos) {
      _studentLatLng = LatLng(pos.latitude, pos.longitude);
      _safeNotify();
    }, onError: (_) {});
  }

  void stopTracking() {
    _tripSub?.cancel();
    _gpsSub?.cancel();
    _studentSub?.cancel();
    _notifyThrottle?.cancel();
    _agoTicker?.cancel();
    _tripSub = null;
    _gpsSub = null;
    _studentSub = null;
    _agoTicker = null;
    _trip = null;
    _gps = null;
  }

  void _safeNotify() {
    if (_disposed) return;
    _dirty = true;
    _notifyThrottle ??= Timer(const Duration(milliseconds: 400), () {
      _notifyThrottle = null;
      if (_disposed || !_dirty) return;
      _dirty = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    stopTracking();
    super.dispose();
  }
}
