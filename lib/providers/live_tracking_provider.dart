import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
  bool get isBusLive => (_gps?.isLive ?? false) || (_trip?.isActive == true && busLatLng != null);

  String get statusLabel {
    if (_trip == null) return 'Bus is not currently active';
    if (_gps?.isLive == true) return 'Live';
    if (_trip!.isActive) return 'Waiting for GPS…';
    return 'Trip ended';
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
    final routeId = student.assignedRouteId?.trim() ?? _route?.id ?? '';
    final driverId = student.assignedDriverId?.trim() ??
        _route?.driverId?.trim() ??
        '';

    Stream<TripModel?> stream;
    if (busId.isNotEmpty) {
      stream = _trips.watchActiveTripForBus(busId);
    } else if (routeId.isNotEmpty) {
      stream = _trips.watchActiveTripForRoute(routeId);
    } else if (driverId.isNotEmpty) {
      stream = _trips.watchActiveTripForDriver(driverId);
    } else {
      _trip = null;
      _gps = null;
      _error = 'No bus or route assigned. Contact Admin.';
      _safeNotify();
      return;
    }

    _tripSub = stream.listen((trip) {
      _trip = trip;
      _gpsSub?.cancel();
      if (trip == null) {
        _gps = null;
        _safeNotify();
        return;
      }
      _gpsSub = _trips.watchTripGps(trip.id).listen((gps) {
        _gps = gps;
        _safeNotify();
      }, onError: (e) {
        _error = 'GPS stream error: $e';
        _safeNotify();
      });
      _safeNotify();
    }, onError: (e) {
      _error = 'Trip stream error: $e';
      _safeNotify();
    });
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
    _tripSub = null;
    _gpsSub = null;
    _studentSub = null;
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
