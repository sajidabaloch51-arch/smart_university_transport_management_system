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

  Stream<List<DriverModel>> streamDrivers() {
    final db = FirebaseFirestore.instance;
    if (Firebase.apps.isEmpty) return Stream.value([_driver!].whereType<DriverModel>().toList());

    return db.collection('users')
        .where('role', isEqualTo: 'driver')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Initialize driver data
  Future<void> init(String driverId) async {
    // If Firebase isn't ready, load mock data immediately for demo
    if (Firebase.apps.isEmpty) {
      _loadMockData();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _driver = await _firestoreService.getDriverData(driverId);
      
      if (_driver == null) {
        _loadMockData();
      } else {
        _subscribeToRealtimeStreams();
      }
    } catch (e) {
      debugPrint("Firebase error: $e. Loading mock data for demo.");
      _loadMockData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockData() {
    _driver = DriverModel(
      uid: 'drv_001',
      name: 'Nasir Ali',
      email: 'nasir.ali@uog.edu.pk',
      phone: '+92 300 1234567',
      role: 'driver',
      driverId: 'ID-2024-005',
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
      startPoint: 'City Center',
      endPoint: 'University Main Gate',
      stops: [
        RouteStop(stopName: 'Bus Stand', lat: 25.12, lng: 62.32, order: 1),
        RouteStop(stopName: 'Fish Harbor', lat: 25.13, lng: 62.33, order: 2),
        RouteStop(stopName: 'University Gate', lat: 25.14, lng: 62.34, order: 3),
      ],
      totalDistance: '15 km',
      estimatedDuration: '35 min',
    );

    _todaySchedules = [
      ScheduleModel(
        id: 'sch_01',
        busNumber: 'UOG-101',
        routeName: 'Route A',
        departureTime: '07:30 AM',
        arrivalTime: '08:15 AM',
        days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
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
        
        _driver = DriverModel(
          uid: _driver!.uid,
          name: _driver!.name,
          email: _driver!.email,
          phone: _driver!.phone,
          role: _driver!.role,
          driverId: _driver!.driverId,
          profileImg: _driver!.profileImg,
          assignedBusId: _driver!.assignedBusId,
          assignedBusNumber: _driver!.assignedBusNumber,
          assignedRouteId: _driver!.assignedRouteId,
          assignedRouteName: _driver!.assignedRouteName,
          isOnDuty: true,
          lastDutyStart: DateTime.now(),
        );
        
        _startLocationTracking();
        _startTimer();
        await _firestoreService.updateDriverStatus(_driver!.uid, true);
      } else {
        _driver = DriverModel(
          uid: _driver!.uid,
          name: _driver!.name,
          email: _driver!.email,
          phone: _driver!.phone,
          role: _driver!.role,
          driverId: _driver!.driverId,
          profileImg: _driver!.profileImg,
          assignedBusId: _driver!.assignedBusId,
          assignedBusNumber: _driver!.assignedBusNumber,
          assignedRouteId: _driver!.assignedRouteId,
          assignedRouteName: _driver!.assignedRouteName,
          isOnDuty: false,
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
