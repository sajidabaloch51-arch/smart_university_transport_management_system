import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart';
import '../models/notice_model.dart';
import '../models/schedule_model.dart';

class FirestoreService {
  // Safe getter for FirebaseFirestore
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (e) {}
    return null;
  }

  // Helper to handle Firebase calls with a fast timeout for better UX
  Future<T?> _withTimeout<T>(Future<T?> Function(FirebaseFirestore db) call) async {
    final db = _db;
    if (db == null) return null;
    
    try {
      return await call(db).timeout(const Duration(seconds: 2));
    } catch (e) {
      print("Firebase Timeout/Error: $e");
      return null;
    }
  }

  // --- USER OPERATIONS ---
  Future<void> createUser(UserModel user) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<UserModel?> getUser(String uid) async {
    return await _withTimeout<UserModel>((db) async {
      var doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Stream<List<UserModel>> getUsers(String role) {
    final db = _db;
    if (db == null) return const Stream.empty();
    
    return db.collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // --- STUDENT OPERATIONS ---
  Stream<List<StudentModel>> streamStudents() {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db.collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- DRIVER OPERATIONS ---
  Future<DriverModel?> getDriverData(String driverId) async {
    return await _withTimeout<DriverModel>((db) async {
      final doc = await db.collection('users').doc(driverId).get();
      if (doc.exists) {
        return DriverModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateDriverStatus(String driverId, bool isOnDuty) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('users').doc(driverId).update({
        'isOnDuty': isOnDuty,
        'lastDutyStart': isOnDuty ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print(e);
    }
  }

  // --- ROUTE OPERATIONS ---
  Stream<List<RouteModel>> getRoutes(String universityId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db
        .collection('routes')
        .where('universityId', isEqualTo: universityId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<RouteModel?> getRoute(String routeId) {
    final db = _db;
    if (db == null) return Stream.value(null);

    return db.collection('routes').doc(routeId).snapshots().map((doc) {
      if (doc.exists) {
        return RouteModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Stream<RouteModel?> getAssignedRoute(String routeId) => getRoute(routeId);

  Future<void> addRoute(RouteModel route) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('routes').doc(route.id).set(route.toMap());
    } catch (e) {
      print(e);
    }
  }

  // --- SCHEDULE OPERATIONS ---
  Stream<List<ScheduleModel>> getSchedules(String routeId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db
        .collection('schedules')
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ScheduleModel>> getTodaySchedules(String routeId) => getSchedules(routeId);

  // --- NOTICE OPERATIONS ---
  Stream<List<NoticeModel>> getNotices(String universityId) {
    final db = _db;
    if (db == null) return const Stream.empty();

    return db
        .collection('notices')
        .where('universityId', isEqualTo: universityId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addNotice(NoticeModel notice) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('notices').doc(notice.id).set(notice.toMap());
    } catch (e) {
      print(e);
    }
  }

  // --- FEEDBACK ---
  Future<void> addFeedback(Map<String, dynamic> feedback) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('feedback').add(feedback);
    } catch (e) {
      print(e);
    }
  }

  // --- LIVE LOCATION ---
  Stream<DocumentSnapshot> getDriverLocation(String driverId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db.collection('liveLocations').doc(driverId).snapshots();
  }

  Future<void> updateLiveLocation(String driverId, Map<String, dynamic> locationData) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection('liveLocations').doc(driverId).set(locationData, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }
}
