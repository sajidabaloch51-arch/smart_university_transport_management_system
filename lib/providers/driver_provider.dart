import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart';
import '../models/notice_model.dart';
import '../models/schedule_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class DriverProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  DriverModel? _driver;
  RouteModel? _assignedRoute;
  List<NoticeModel> _notices = [];
  List<ScheduleModel> _todaySchedules = [];
  
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  
  // Local cache for registered drivers
  final Map<String, DriverModel> _localDrivers = {};

  StreamSubscription? _positionSubscription;
  Timer? _dutyTimer;
  Duration _dutyDuration = Duration.zero;

  // Getters
  DriverModel? get driver => _driver;
  RouteModel? get assignedRoute => _assignedRoute;
  List<NoticeModel> get notices => _notices;
  List<ScheduleModel> get todaySchedules => _todaySchedules;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration get dutyDuration => _dutyDuration;

  // Safe getter for FirebaseFirestore
  FirebaseFirestore? get _db {
    try {
      // Check if Firebase is initialized and default app exists
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {}
    return null;
  }

  Stream<List<DriverModel>> streamDrivers() {
    return Stream.value(_localDrivers.values.toList());
  }

  Future<void> updateDriver(DriverModel driver) async {
    // Update local cache first so registration/login feels instant
    _localDrivers[driver.uid] = driver;
    if (_driver?.uid == driver.uid) {
      _driver = driver;
    }
    notifyListeners();

    final db = _db;
    if (db == null) return;

    db.collection('users').doc(driver.uid).set(driver.toMap(), SetOptions(merge: true)).then(
      (_) {},
      onError: (e) => debugPrint("Error updating driver: $e"),
    );
  }

  Future<void> updateProfileImage(String base64Img) async {
    if (_driver == null) return;
    
    final updatedDriver = _driver!.copyWith(profileImg: base64Img);
    await updateDriver(updatedDriver);
  }

  /// Initialize driver data
  Future<void> init(String driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_localDrivers.containsKey(driverId)) {
        _driver = _localDrivers[driverId];
      } else {
        _loadMockData(driverId);
      }
      _subscribeToRealtimeStreams();
    } catch (e) {
      debugPrint("Driver init error: $e");
      _loadMockData(driverId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockData(String driverId) {
    // Prefer already-registered driver profile; otherwise create a blank shell
    if (_localDrivers.containsKey(driverId)) {
      _driver = _localDrivers[driverId];
    } else {
      _driver = DriverModel(
        uid: driverId,
        name: 'Driver',
        email: '',
        phone: '',
        role: 'driver',
        driverId: driverId,
        licenseNumber: '',
        profileImg: '',
        assignedBusId: '',
        assignedBusNumber: 'Not Assigned',
        assignedRouteId: '',
        assignedRouteName: 'Not Assigned',
        isOnDuty: false,
        status: 'Active',
      );
      _localDrivers[driverId] = _driver!;
    }
    _assignedRoute = null;
    _todaySchedules = [];
    _notices = [];
    notifyListeners();
  }

  void _subscribeToRealtimeStreams() {
    if (_driver == null || Firebase.apps.isEmpty) return;

    _firestoreService.getAssignedRoute(_driver!.assignedRouteId).listen((route) {
      if (route != null) {
        _assignedRoute = route;
        notifyListeners();
      }
    });

    _firestoreService.getTodaySchedules(_driver!.assignedRouteId).listen((schedules) {
      _todaySchedules = schedules;
      notifyListeners();
    });

    _firestoreService.getNotices('uog').listen((notices) {
      _notices = notices;
      notifyListeners();
    });

    if (_driver!.isOnDuty) {
      _startLocationTracking();
      _startTimer();
    }
  }

  /// Toggle Duty Status
  Future<void> toggleDuty() async {
    if (_driver == null) return;

    bool newStatus = !_driver!.isOnDuty;
    _isLoading = true;
    notifyListeners();

    try {
      if (newStatus) {
        bool hasPermission = true;
        try {
          hasPermission = await _locationService.checkPermissions();
        } catch (_) {
          // Web/desktop may not support geolocation; allow duty anyway
          hasPermission = true;
        }
        if (!hasPermission) throw Exception('Location permissions required');
        
        _driver = _driver!.copyWith(
          isOnDuty: true,
          lastDutyStart: DateTime.now(),
        );
        _localDrivers[_driver!.uid] = _driver!;
        
        _startLocationTracking();
        _startTimer();
        _firestoreService.updateDriverStatus(_driver!.uid, true);
      } else {
        _driver = _driver!.copyWith(
          isOnDuty: false,
          lastDutyStart: null,
        );
        _localDrivers[_driver!.uid] = _driver!;
        _stopLocationTracking();
        _stopTimer();
        _firestoreService.updateDriverStatus(_driver!.uid, false);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startLocationTracking() {
    if (Firebase.apps.isEmpty) return;
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((pos) {
      _currentPosition = pos;
      _firestoreService.updateLiveLocation(_driver!.uid, {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
        'isOnDuty': true,
        'lastUpdated': DateTime.now(),
      });
      notifyListeners();
    });
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentPosition = null;
    notifyListeners();
  }

  void _startTimer() {
    _dutyTimer?.cancel();
    _dutyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_driver?.lastDutyStart != null) {
        _dutyDuration = DateTime.now().difference(_driver!.lastDutyStart!);
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _dutyTimer?.cancel();
    _dutyTimer = null;
    _dutyDuration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _dutyTimer?.cancel();
    super.dispose();
  }
}
