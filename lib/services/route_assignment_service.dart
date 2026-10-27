import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for route ↔ driver/bus assignment:
/// `routes/{routeId}.driverId`, `driverName`, `driverPhone`, `busNo`.
///
/// Also mirrors limited public fields to `driverPublic/{driverId}` so students
/// never need private user fields (email, etc.).
class RouteAssignmentService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _routes {
    final db = _db;
    return db?.collection('routes');
  }

  /// Assigns [driverId] to [routeId] by stable id (never by route name).
  Future<void> assignDriverToRoute({
    required String routeId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String busNo,
    bool clearFromOtherRoutes = true,
  }) async {
    final routes = _routes;
    final db = _db;
    if (routes == null || db == null) {
      throw Exception('Firestore not available.');
    }
    if (routeId.isEmpty || driverId.isEmpty) {
      throw ArgumentError('routeId and driverId are required');
    }

    debugPrint(
      'RouteAssignment assign routeId=$routeId driverId=$driverId busNo=$busNo',
    );

    if (clearFromOtherRoutes) {
      await _clearDriverFromOtherRoutes(driverId, exceptRouteId: routeId);
    }

    await routes.doc(routeId).set({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'busNo': busNo,
    }, SetOptions(merge: true));

    await db.collection('driverPublic').doc(driverId).set({
      'name': driverName,
      'phone': driverPhone,
      'busNo': busNo,
      'routeId': routeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep driver profile in sync (same routeId).
    await db.collection('users').doc(driverId).set({
      'assignedRouteId': routeId,
      'assignedBusNumber': busNo,
      if (driverName.isNotEmpty) 'name': driverName,
      if (driverPhone.isNotEmpty) 'phone': driverPhone,
    }, SetOptions(merge: true));
  }

  Future<void> unassignDriverFromRoute(String routeId) async {
    final routes = _routes;
    final db = _db;
    if (routes == null || db == null) {
      throw Exception('Firestore not available.');
    }

    final snap = await routes.doc(routeId).get();
    final prevDriverId = snap.data()?['driverId']?.toString();

    await routes.doc(routeId).set({
      'driverId': null,
      'driverName': '',
      'driverPhone': '',
      'busNo': '',
    }, SetOptions(merge: true));

    if (prevDriverId != null && prevDriverId.isNotEmpty) {
      await db.collection('users').doc(prevDriverId).set({
        'assignedRouteId': '',
        'assignedRouteName': 'Not Assigned',
        'assignedBusNumber': 'Not Assigned',
      }, SetOptions(merge: true));
      await db.collection('driverPublic').doc(prevDriverId).set({
        'routeId': null,
        'busNo': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    debugPrint('RouteAssignment unassign routeId=$routeId');
  }

  Future<void> _clearDriverFromOtherRoutes(
    String driverId, {
    String? exceptRouteId,
  }) async {
    final routes = _routes;
    if (routes == null) return;
    final snap =
        await routes.where('driverId', isEqualTo: driverId).get();
    for (final doc in snap.docs) {
      if (exceptRouteId != null && doc.id == exceptRouteId) continue;
      await doc.reference.set({
        'driverId': null,
        'driverName': '',
        'driverPhone': '',
        'busNo': '',
      }, SetOptions(merge: true));
    }
  }

  /// One-time / Admin migration: fill routes.driverId from drivers + duties.
  /// Returns how many routes were updated.
  Future<int> migrateAssignmentsFromExistingData() async {
    final db = _db;
    final routesCol = _routes;
    if (db == null || routesCol == null) {
      throw Exception('Firestore not available.');
    }

    var updated = 0;
    final routesSnap = await routesCol.get();
    final routesById = {for (final d in routesSnap.docs) d.id: d};
    final routesByName = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in routesSnap.docs) {
      final name = d.data()['routeName']?.toString().trim().toLowerCase() ?? '';
      if (name.isNotEmpty) routesByName[name] = d;
    }

    // 1) Drivers with assignedRouteId
    final drivers = await db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    for (final doc in drivers.docs) {
      final data = doc.data();
      final routeId = data['assignedRouteId']?.toString().trim() ?? '';
      if (routeId.isEmpty || routeId == 'Not Assigned') continue;
      if (!routesById.containsKey(routeId)) continue;
      final routeData = routesById[routeId]!.data();
      if ((routeData['driverId']?.toString() ?? '').isNotEmpty) continue;

      await assignDriverToRoute(
        routeId: routeId,
        driverId: doc.id,
        driverName: data['name']?.toString() ?? '',
        driverPhone: data['phone']?.toString() ?? '',
        busNo: data['assignedBusNumber']?.toString() ?? '',
        clearFromOtherRoutes: false,
      );
      updated++;
    }

    // 2) Recent duties: match by routeId if present, else route name (legacy).
    final duties = await db.collection('duties').get();
    for (final doc in duties.docs) {
      final data = doc.data();
      if (data['status']?.toString() == 'cancelled') continue;
      final driverId = data['driverId']?.toString() ?? '';
      if (driverId.isEmpty) continue;

      String? routeId = data['routeId']?.toString();
      if (routeId == null || routeId.isEmpty) {
        final name = data['route']?.toString().trim().toLowerCase() ?? '';
        routeId = routesByName[name]?.id;
      }
      if (routeId == null || !routesById.containsKey(routeId)) continue;

      final routeData = routesById[routeId]!.data();
      if ((routeData['driverId']?.toString() ?? '').isNotEmpty) continue;

      String phone = '';
      try {
        final user = await db.collection('users').doc(driverId).get();
        phone = user.data()?['phone']?.toString() ?? '';
      } catch (_) {}

      await assignDriverToRoute(
        routeId: routeId,
        driverId: driverId,
        driverName: data['driverName']?.toString() ?? '',
        driverPhone: phone,
        busNo: data['busNo']?.toString() ?? '',
        clearFromOtherRoutes: false,
      );
      updated++;
    }

    debugPrint('RouteAssignment migrate updated=$updated routes');
    return updated;
  }
}
