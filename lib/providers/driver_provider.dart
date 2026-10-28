import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart';
import '../models/notice_model.dart';
import '../models/schedule_model.dart';
import '../models/bus_live_location_model.dart';
import '../services/firestore_service.dart';
import '../services/live_firestore.dart';
import '../services/location_service.dart';
import '../services/realtime_location_service.dart';
import '../services/route_assignment_service.dart';

class DriverProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final RealtimeLocationService _realtimeLocation = RealtimeLocationService();

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
  StreamSubscription? _profileSubscription;
  StreamSubscription? _routeSubscription;
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
    } catch (_) {
      // Firebase not ready yet
    }
    return null;
  }

  static const _driversKey = 'users_drivers';
  List<DriverModel> _cachedDrivers = const [];
  List<DriverModel> get cachedDrivers => _cachedDrivers;

  /// New mapped stream per call — LiveFirestore broadcast supports many listeners.
  /// Emits cached drivers immediately so Admin never waits on a cold network.
  Stream<List<DriverModel>> streamDrivers() {
    if (_db == null) {
      return Stream.value(_localDrivers.values.toList());
    }
    final live = LiveFirestore.mapSnapshots(
      _driversKey,
      (db) => db.collection('users').where('role', isEqualTo: 'driver'),
      (snapshot) {
        final list = <DriverModel>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(DriverModel.fromMap(doc.data(), doc.id));
          } catch (e, st) {
            debugPrint('⚠️ Skipping bad driver doc id=${doc.id}: $e\n$st');
          }
        }
        for (final d in list) {
          _localDrivers[d.uid] = d;
        }
        _cachedDrivers = list;
        return list;
      },
      collectionLabel: 'users(role=driver)',
    );
    final seed = _cachedDrivers;
    if (seed.isEmpty) return live;
    return Stream<List<DriverModel>>.multi((controller) {
      controller.add(seed);
      final sub = live.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  void restartDriversStream() {
    LiveFirestore.restart(_driversKey);
  }

  Future<void> refreshDrivers() => LiveFirestore.forceRefresh(_driversKey);

  Future<void> deleteDriver(String uid) async {
    final db = _db;
    if (db == null) return;
    await RouteAssignmentService().clearBeforeDriverDelete(uid);
    await db.collection('users').doc(uid).delete();
    try {
      await db.collection('driverPublic').doc(uid).delete();
    } catch (_) {}
    _localDrivers.remove(uid);
    _cachedDrivers =
        _cachedDrivers.where((d) => d.uid != uid).toList(growable: false);
    notifyListeners();
  }

  Future<void> updateDriver(DriverModel driver) async {
    _localDrivers[driver.uid] = driver;
    if (_driver?.uid == driver.uid) {
      _driver = driver;
    }
    notifyListeners();

    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }

    await db
        .collection('users')
        .doc(driver.uid)
        .set(driver.toMap(), SetOptions(merge: true));
  }

  Future<void> updateProfileImage(String base64Img) async {
    if (_driver == null) return;
    
    final updatedDriver = _driver!.copyWith(profileImg: base64Img);
    await updateDriver(updatedDriver);
  }

  /// Initialize driver data from Firestore (local cache as fallback).
  /// Shows cached profile immediately so the dashboard is not blocked.
  Future<void> init(String driverId) async {
    _error = null;

    // Paint UI instantly from memory when possible.
    if (_localDrivers.containsKey(driverId)) {
      _driver = _localDrivers[driverId];
      _isLoading = false;
      notifyListeners();
      _subscribeToRealtimeStreams();
    } else if (_driver?.uid != driverId) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final db = _db;
      if (db != null) {
        var doc = await db
            .collection('users')
            .doc(driverId)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 4));

        // Auth uid often ≠ seed users doc id (e.g. driver_id). Resolve by email.
        if (!doc.exists) {
          String? email;
          try {
            email = FirebaseAuth.instance.currentUser?.email;
          } catch (_) {}
          if (email != null && email.isNotEmpty) {
            final profile =
                await _firestoreService.getUserAuthProfile(email);
            if (profile != null && profile.uid.isNotEmpty) {
              final linked = await db
                  .collection('users')
                  .doc(profile.uid)
                  .get(const GetOptions(source: Source.serverAndCache))
                  .timeout(const Duration(seconds: 4));
              if (linked.exists) {
                doc = linked;
                debugPrint(
                  'DriverProvider.init: linked $driverId → ${doc.id} via email',
                );
              }
            }
          }
        }

        if (doc.exists && doc.data() != null) {
          _driver = DriverModel.fromMap(doc.data()!, doc.id);
          _localDrivers[_driver!.uid] = _driver!;
          _localDrivers[driverId] = _driver!;
        } else if (_localDrivers.containsKey(driverId)) {
          _driver = _localDrivers[driverId];
        } else if (_driver == null) {
          _loadMockData(driverId);
        }
      } else if (_driver == null) {
        if (_localDrivers.containsKey(driverId)) {
          _driver = _localDrivers[driverId];
        } else {
          _loadMockData(driverId);
        }
      }
      _subscribeToRealtimeStreams();
    } catch (e) {
      debugPrint("Driver init error: $e");
      if (_driver == null) _loadMockData(driverId);
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
    final db = _db;
    if (db == null) return;

    // Live profile so Admin assignment changes appear without re-login.
    _profileSubscription?.cancel();
    _profileSubscription =
        db.collection('users').doc(_driver!.uid).snapshots().listen((doc) {
      if (!doc.exists || doc.data() == null) return;
      final next = DriverModel.fromMap(doc.data()!, doc.id);
      final routeChanged = next.assignedRouteId != _driver?.assignedRouteId;
      _driver = next;
      _localDrivers[next.uid] = next;
      notifyListeners();
      if (routeChanged) {
        _subscribeAssignedRoute(next.assignedRouteId);
      }
    });

    _subscribeAssignedRoute(_driver!.assignedRouteId);

    // Notices are shown via AlertService on the dashboard — do not subscribe
    // to the old notices composite-index query (it slows / fails cold start).

    if (_driver!.isOnDuty) {
      _startLocationTracking();
      _startTimer();
    }
  }

  void _subscribeAssignedRoute(String routeId) {
    _routeSubscription?.cancel();
    _routeSubscription = null;
    _assignedRoute = null;
    _todaySchedules = [];
    if (routeId.isEmpty || routeId.toLowerCase() == 'not assigned') {
      notifyListeners();
      return;
    }
    _routeSubscription =
        _firestoreService.getAssignedRoute(routeId).listen((route) {
      _assignedRoute = route;
      notifyListeners();
    });
    _firestoreService.getTodaySchedules(routeId).listen((schedules) {
      _todaySchedules = schedules;
      notifyListeners();
    });
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
        await _firestoreService.updateDriverStatus(_driver!.uid, true);
        // Seed RTDB immediately so students see Live before first GPS tick
        await _publishLiveLocation(
          lat: _currentPosition?.latitude ?? 0,
          lng: _currentPosition?.longitude ?? 0,
          speed: _currentPosition?.speed ?? 0,
          heading: _currentPosition?.heading ?? 0,
          isOnDuty: true,
        );
      } else {
        _driver = _driver!.copyWith(
          isOnDuty: false,
          lastDutyStart: null,
        );
        _localDrivers[_driver!.uid] = _driver!;
        _stopLocationTracking();
        _stopTimer();
        await _firestoreService.updateDriverStatus(_driver!.uid, false);
        await _realtimeLocation.markOffline(_driver!.uid);
        // Keep Firestore mirror in sync
        await _firestoreService.updateLiveLocation(_driver!.uid, {
          'isOnDuty': false,
          'lastUpdated': DateTime.now(),
        });
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

    // One-shot fix so first publish has real coords
    _locationService.getCurrentLocation().then((pos) {
      _currentPosition = pos;
      _publishLiveLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        speed: pos.speed,
        heading: pos.heading,
        isOnDuty: true,
      );
      notifyListeners();
    }).catchError((e) {
      debugPrint('Initial GPS fix failed: $e');
    });

    _positionSubscription = _locationService.getPositionStream().listen((pos) {
      _currentPosition = pos;
      _publishLiveLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        speed: pos.speed,
        heading: pos.heading,
        isOnDuty: true,
      );
      notifyListeners();
    }, onError: (e) {
      debugPrint('GPS stream error: $e');
      _error = 'Location stream failed: $e';
      notifyListeners();
    });
  }

  Future<void> _publishLiveLocation({
    required double lat,
    required double lng,
    required double speed,
    required double heading,
    required bool isOnDuty,
  }) async {
    if (_driver == null) return;

    final payload = BusLiveLocationModel(
      driverId: _driver!.uid,
      driverName: _driver!.name,
      busId: _driver!.assignedBusId,
      busNumber: _driver!.assignedBusNumber,
      routeId: _driver!.assignedRouteId,
      routeName: _driver!.assignedRouteName,
      lat: lat,
      lng: lng,
      speed: speed,
      heading: heading,
      isOnDuty: isOnDuty,
      lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
    );

    // Primary: Firebase Realtime Database (students listen here)
    try {
      await _realtimeLocation.publishLocation(payload);
    } catch (e) {
      debugPrint('RTDB publish failed: $e');
    }

    // Secondary mirror: Firestore (legacy screens / fallback)
    try {
      await _firestoreService.updateLiveLocation(_driver!.uid, {
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'isOnDuty': isOnDuty,
        'routeId': _driver!.assignedRouteId,
        'busId': _driver!.assignedBusId,
        'busNumber': _driver!.assignedBusNumber,
        'driverName': _driver!.name,
        'routeName': _driver!.assignedRouteName,
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Firestore liveLocation mirror failed: $e');
    }
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
    _profileSubscription?.cancel();
    _routeSubscription?.cancel();
    _dutyTimer?.cancel();
    super.dispose();
  }
}
