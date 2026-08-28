import 'dart:async';
import 'package:flutter/material.dart';
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
  
  StreamSubscription<Position>? _positionSubscription;
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

  /// Initialize driver data and sub-collections
  Future<void> init(String driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _driver = await _firestoreService.getDriverData(driverId);
      if (_driver != null) {
        // Fetch route
        _firestoreService.getAssignedRoute(_driver!.assignedRouteId).listen((route) {
          _assignedRoute = route;
          notifyListeners();
        });

        // Fetch schedules
        _firestoreService.getTodaySchedules(_driver!.assignedRouteId).listen((schedules) {
          _todaySchedules = schedules;
          notifyListeners();
        });

        // Fetch notices
        _firestoreService.getNotices().listen((notices) {
          _notices = notices;
          notifyListeners();
        });

        if (_driver!.isOnDuty) {
          _startLocationTracking();
          _startTimer();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
        
        await _firestoreService.updateDriverStatus(_driver!.id, true);
        _driver = await _firestoreService.getDriverData(_driver!.id); // Refresh local data
        _startLocationTracking();
        _startTimer();
      } else {
        await _firestoreService.updateDriverStatus(_driver!.id, false);
        _driver = await _firestoreService.getDriverData(_driver!.id); // Refresh local data
        _stopLocationTracking();
        _stopTimer();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((position) {
      _currentPosition = position;
      _firestoreService.updateLiveLocation(_driver!.id, {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
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
