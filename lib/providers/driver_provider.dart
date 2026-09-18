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
  
  // Local cache for demo mode
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
    try {
      final db = _db;
      if (db == null) return Stream.value(_localDrivers.values.toList());

      return db.collection('users')
          .where('role', isEqualTo: 'driver')
          .snapshots()
          .map((snapshot) {
            final drivers = snapshot.docs
              .map((doc) => DriverModel.fromMap(doc.data(), doc.id))
              .toList();
            // Update local cache
            for (var d in drivers) { _localDrivers[d.uid] = d; }
            return drivers;
          });
    } catch (e) {
      debugPrint("Error in streamDrivers: $e");
      return Stream.value(_localDrivers.values.toList());
    }
  }

  Future<void> updateDriver(DriverModel driver) async {
    try {
      // Update local cache
      _localDrivers[driver.uid] = driver;
      if (_driver?.uid == driver.uid) {
        _driver = driver;
      }
      notifyListeners();

      final db = _db;
      if (db == null) return;

      _isLoading = true;
      notifyListeners();
      await db.collection('users').doc(driver.uid).set(driver.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating driver: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      // Prioritize Firestore data for the actual logged-in user
      final firestoreDriver = await _firestoreService.getDriverData(driverId);
      
      if (firestoreDriver != null) {
        _driver = firestoreDriver;
        _localDrivers[driverId] = _driver!;
        _subscribeToRealtimeStreams();
      } else {
        // Only fallback to mock if absolutely necessary (e.g., demo/no internet)
        // but try to keep it as realistic as possible
        if (_localDrivers.containsKey(driverId)) {
          _driver = _localDrivers[driverId];
          _subscribeToRealtimeStreams();
        } else {
          _loadMockData(driverId);
        }
      }
    } catch (e) {
      debugPrint("Driver init error: $e");
      _loadMockData(driverId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockData(String driverId) {
    _driver = DriverModel(
      uid: driverId,
      name: driverId.contains('drv') ? 'Nasir Ali' : 'Registered Driver',
      email: driverId.contains('drv') ? 'nasir.ali@uog.edu.pk' : 'driver@uog.edu.pk',
      phone: '+92 300 1234567',
      role: 'driver',
      driverId: 'ID-2024-005',
      licenseNumber: 'LNC-998877',
      cnicOrLicense: '34101-1234567-1',
      licenseExpiryDate: DateTime.now().add(const Duration(days: 365)),
      address: 'Main Street, Gwadar',
      experienceYears: 10,
      status: 'Active',
      profileImg: '',
      assignedBusId: 'bus_01',
      assignedBusNumber: 'UOG-101',
      assignedRouteId: 'route_01',
      assignedRouteName: 'Gwadar City Center - Route A',
      isOnDuty: false,
    );

    _assignedRoute = RouteModel(
      id: 'route_01',
      universityId: 'uog',
      routeName: 'Gwadar City Center',
      routeNumber: 'A',
      startLocation: 'City Center',
      endLocation: 'University Main Gate',
      viaStops: ['Bus Stand', 'Fish Harbor'],
      stops: [
        RouteStop(stopName: 'Bus Stand', lat: 25.12, lng: 62.32, order: 1),
        RouteStop(stopName: 'Fish Harbor', lat: 25.13, lng: 62.33, order: 2),
        RouteStop(stopName: 'University Gate', lat: 25.14, lng: 62.34, order: 3),
      ],
      distanceKm: '15 km',
      estimatedTime: '35 min',
    );

    _todaySchedules = [
      ScheduleModel(
        id: 'sch_01',
        driverId: driverId,
        driverName: 'Nasir Ali',
        routeId: 'route_01',
        routeName: 'Route A',
        date: DateTime.now(),
        departureTime: '07:30 AM',
        arrivalTime: '08:15 AM',
        shift: 'Morning',
        vehicleNo: 'UOG-101',
        status: 'Scheduled',
      )
    ];

    _notices = [
      NoticeModel(
        id: 'n_01',
        title: 'Route A Diversion',
        description: 'Please follow the bypass road due to construction at Fish Harbor.',
        date: DateTime.now(),
        type: NoticeType.delay,
        postedBy: 'Transport Admin',
      ),
    ];

    _localDrivers[_driver!.uid] = _driver!;
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
        bool hasPermission = await _locationService.checkPermissions();
        if (!hasPermission) throw Exception('Location permissions required');
        
        _driver = _driver!.copyWith(
          isOnDuty: true,
          lastDutyStart: DateTime.now(),
        );
        
        _startLocationTracking();
        _startTimer();
        await _firestoreService.updateDriverStatus(_driver!.uid, true);
      } else {
        _driver = _driver!.copyWith(
          isOnDuty: false,
          lastDutyStart: null,
        );
        _stopLocationTracking();
        _stopTimer();
        await _firestoreService.updateDriverStatus(_driver!.uid, false);
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
      if (pos is Position) {
        _currentPosition = pos;
        _firestoreService.updateLiveLocation(_driver!.uid, {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'speed': pos.speed,
          'isOnDuty': true,
          'lastUpdated': DateTime.now(),
        });
        notifyListeners();
      }
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
