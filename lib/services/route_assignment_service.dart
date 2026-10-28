import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for driver ↔ route ↔ bus assignment.
///
/// Linked fields (always updated together in one batch):
/// - users/{driverId}: assignedRouteId, assignedRouteName, assignedBusId, assignedBusNumber
/// - routes/{routeId}: driverId, driverName, driverPhone, busId, busNo
/// - buses/{busId}: assignedDriverId, assignedDriverName, assignedRouteId, assignedRouteName
/// - driverPublic/{driverId}: name, phone, busNo, routeId (student-safe)
class RouteAssignmentService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  /// Assign [driverId] + optional [busId] to [routeId] (or clear all when
  /// [routeId]/[busId] empty). Clears previous links so one driver/bus
  /// never stay attached to multiple parents.
  Future<void> assign({
    required String driverId,
    required String driverName,
    required String driverPhone,
    String routeId = '',
    String busId = '',
    bool confirmReplace = true,
  }) async {
    final db = _db;
    if (db == null) throw Exception('Firestore not available.');
    if (driverId.isEmpty) throw ArgumentError('driverId is required');

    final routeRef =
        routeId.isEmpty ? null : db.collection('routes').doc(routeId);
    final busRef = busId.isEmpty ? null : db.collection('buses').doc(busId);
    final driverRef = db.collection('users').doc(driverId);

    String routeName = '';
    String busNo = '';

    if (routeRef != null) {
      final r = await routeRef.get();
      if (!r.exists) {
        throw StateError('Route no longer exists. Pick another route.');
      }
      routeName = r.data()?['routeName']?.toString() ?? '';
    }
    if (busRef != null) {
      final b = await busRef.get();
      if (!b.exists) {
        throw StateError('Bus no longer exists. Pick another bus.');
      }
      busNo = b.data()?['busNumber']?.toString() ?? '';
      // If route not chosen but bus has a route, keep bus's route for display.
      if (routeId.isEmpty) {
        final busRouteId = b.data()?['assignedRouteId']?.toString() ?? '';
        if (busRouteId.isNotEmpty) {
          routeId = busRouteId;
          final r = await db.collection('routes').doc(routeId).get();
          routeName = r.data()?['routeName']?.toString() ?? '';
        }
      }
    }

    // Discover previous owners that must be cleared.
    final prevDriver = await driverRef.get();
    final prevRouteId = prevDriver.data()?['assignedRouteId']?.toString() ?? '';
    final prevBusId = prevDriver.data()?['assignedBusId']?.toString() ?? '';

    String? routeOldDriverId;
    String? routeOldBusId;
    if (routeId.isNotEmpty) {
      final r = await db.collection('routes').doc(routeId).get();
      routeOldDriverId = r.data()?['driverId']?.toString();
      routeOldBusId = r.data()?['busId']?.toString();
    }
    String? busOldDriverId;
    if (busId.isNotEmpty) {
      final b = await db.collection('buses').doc(busId).get();
      busOldDriverId = b.data()?['assignedDriverId']?.toString();
    }

    debugPrint(
      'Assignment SoT driver=$driverId route=$routeId bus=$busId '
      'busNo=$busNo confirmReplace=$confirmReplace',
    );

    final batch = db.batch();

    // Clear this driver's previous route/bus if changing.
    if (prevRouteId.isNotEmpty && prevRouteId != routeId) {
      batch.set(
        db.collection('routes').doc(prevRouteId),
        {
          'driverId': null,
          'driverName': '',
          'driverPhone': '',
          'busId': '',
          'busNo': '',
        },
        SetOptions(merge: true),
      );
    }
    if (prevBusId.isNotEmpty && prevBusId != busId) {
      batch.set(
        db.collection('buses').doc(prevBusId),
        {
          'assignedDriverId': '',
          'assignedDriverName': '',
          'driverId': '',
        },
        SetOptions(merge: true),
      );
    }

    // Clear other driver previously on this route.
    if (routeOldDriverId != null &&
        routeOldDriverId.isNotEmpty &&
        routeOldDriverId != driverId) {
      batch.set(
        db.collection('users').doc(routeOldDriverId),
        {
          'assignedRouteId': '',
          'assignedRouteName': 'Not Assigned',
          'assignedBusId': '',
          'assignedBusNumber': 'Not Assigned',
        },
        SetOptions(merge: true),
      );
      batch.set(
        db.collection('driverPublic').doc(routeOldDriverId),
        {
          'routeId': null,
          'busNo': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // Clear other driver previously on this bus.
    if (busOldDriverId != null &&
        busOldDriverId.isNotEmpty &&
        busOldDriverId != driverId) {
      batch.set(
        db.collection('users').doc(busOldDriverId),
        {
          'assignedBusId': '',
          'assignedBusNumber': 'Not Assigned',
        },
        SetOptions(merge: true),
      );
    }

    // Clear old bus that was on this route (if different).
    if (routeOldBusId != null &&
        routeOldBusId.isNotEmpty &&
        routeOldBusId != busId) {
      batch.set(
        db.collection('buses').doc(routeOldBusId),
        {
          'assignedRouteId': '',
          'assignedRouteName': '',
          'routeId': '',
          'assignedDriverId': '',
          'assignedDriverName': '',
          'driverId': '',
        },
        SetOptions(merge: true),
      );
    }

    // Write driver
    batch.set(
      driverRef,
      {
        'assignedRouteId': routeId,
        'assignedRouteName':
            routeId.isEmpty ? 'Not Assigned' : (routeName.isEmpty ? routeId : routeName),
        'assignedBusId': busId,
        'assignedBusNumber':
            busId.isEmpty ? 'Not Assigned' : (busNo.isEmpty ? busId : busNo),
        if (driverName.isNotEmpty) 'name': driverName,
        if (driverPhone.isNotEmpty) 'phone': driverPhone,
      },
      SetOptions(merge: true),
    );

    // Write route
    if (routeId.isNotEmpty) {
      batch.set(
        db.collection('routes').doc(routeId),
        {
          'driverId': driverId,
          'driverName': driverName,
          'driverPhone': driverPhone,
          'busId': busId,
          'busNo': busNo,
        },
        SetOptions(merge: true),
      );
    }

    // Write bus (assigned* = app fields; driverId/routeId = schema aliases)
    if (busId.isNotEmpty) {
      batch.set(
        db.collection('buses').doc(busId),
        {
          'assignedDriverId': driverId,
          'assignedDriverName': driverName,
          'driverId': driverId,
          'assignedRouteId': routeId,
          'assignedRouteName':
              routeId.isEmpty ? '' : (routeName.isEmpty ? routeId : routeName),
          'routeId': routeId,
        },
        SetOptions(merge: true),
      );
    }

    // Public mirror for students
    batch.set(
      db.collection('driverPublic').doc(driverId),
      {
        'name': driverName,
        'phone': driverPhone,
        'busNo': busNo,
        'routeId': routeId.isEmpty ? null : routeId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Convenience wrappers used by older call sites.
  Future<void> assignDriverToRoute({
    required String routeId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String busNo,
    String busId = '',
    bool clearFromOtherRoutes = true,
  }) async {
    // Resolve busId from busNo when only the number was provided.
    var resolvedBusId = busId;
    if (resolvedBusId.isEmpty && busNo.isNotEmpty && busNo != 'Not Assigned') {
      final db = _db;
      if (db != null) {
        final snap = await db.collection('buses').get();
        for (final d in snap.docs) {
          if ((d.data()['busNumber']?.toString() ?? '') == busNo) {
            resolvedBusId = d.id;
            break;
          }
        }
      }
    }
    await assign(
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      routeId: routeId,
      busId: resolvedBusId,
    );
  }

  Future<void> unassignDriverFromRoute(String routeId) async {
    final db = _db;
    if (db == null) throw Exception('Firestore not available.');
    final snap = await db.collection('routes').doc(routeId).get();
    final prevDriverId = snap.data()?['driverId']?.toString() ?? '';
    if (prevDriverId.isEmpty) {
      await db.collection('routes').doc(routeId).set({
        'driverId': null,
        'driverName': '',
        'driverPhone': '',
        'busId': '',
        'busNo': '',
      }, SetOptions(merge: true));
      return;
    }
    await assign(
      driverId: prevDriverId,
      driverName: snap.data()?['driverName']?.toString() ?? '',
      driverPhone: snap.data()?['driverPhone']?.toString() ?? '',
      routeId: '',
      busId: '',
    );
  }

  /// Admin-only repair: scan routes, buses, duties, drivers and link by ids /
  /// bus numbers / route names. Does not delete anything.
  Future<RepairReport> repairAssignments() async {
    final db = _db;
    if (db == null) throw Exception('Firestore not available.');

    final report = RepairReport();
    final routesSnap = await db.collection('routes').get();
    final busesSnap = await db.collection('buses').get();
    final driversSnap = await db
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();
    final dutiesSnap = await db.collection('duties').get();

    final routesById = {for (final d in routesSnap.docs) d.id: d};
    final routesByName = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in routesSnap.docs) {
      final name =
          d.data()['routeName']?.toString().trim().toLowerCase() ?? '';
      if (name.isNotEmpty) routesByName[name] = d;
    }
    final busesById = {for (final d in busesSnap.docs) d.id: d};
    final busesByNo = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in busesSnap.docs) {
      final no = d.data()['busNumber']?.toString().trim() ?? '';
      if (no.isNotEmpty) busesByNo[no] = d;
    }

    // 1) Drivers that already have assignedRouteId / bus number
    for (final doc in driversSnap.docs) {
      final data = doc.data();
      var routeId = data['assignedRouteId']?.toString().trim() ?? '';
      var busId = data['assignedBusId']?.toString().trim() ?? '';
      final busNo = data['assignedBusNumber']?.toString().trim() ?? '';
      final routeName =
          data['assignedRouteName']?.toString().trim().toLowerCase() ?? '';

      if (routeId.isEmpty || routeId == 'Not Assigned') {
        if (routeName.isNotEmpty && routeName != 'not assigned') {
          routeId = routesByName[routeName]?.id ?? '';
        }
      }
      if (busId.isEmpty &&
          busNo.isNotEmpty &&
          busNo.toLowerCase() != 'not assigned') {
        busId = busesByNo[busNo]?.id ?? '';
      }

      if (routeId.isEmpty && busId.isEmpty) {
        report.skipped.add('Driver ${doc.id}: no route/bus to link');
        continue;
      }
      if (routeId.isNotEmpty && !routesById.containsKey(routeId)) {
        report.unmatched.add('Driver ${doc.id}: routeId $routeId missing');
        continue;
      }
      if (busId.isNotEmpty && !busesById.containsKey(busId)) {
        report.unmatched.add('Driver ${doc.id}: busId $busId missing');
        continue;
      }

      try {
        await assign(
          driverId: doc.id,
          driverName: data['name']?.toString() ?? '',
          driverPhone: data['phone']?.toString() ?? '',
          routeId: routeId,
          busId: busId,
        );
        report.fixed.add(
          'Driver ${doc.id} → route=${routeId.isEmpty ? '-' : routeId} '
          'bus=${busId.isEmpty ? '-' : busId}',
        );
      } catch (e) {
        report.unmatched.add('Driver ${doc.id}: $e');
      }
    }

    // 2) Routes that have driverId but driver profile empty
    for (final doc in routesSnap.docs) {
      final data = doc.data();
      final driverId = data['driverId']?.toString().trim() ?? '';
      if (driverId.isEmpty) continue;
      final driver = await db.collection('users').doc(driverId).get();
      if (!driver.exists) {
        report.unmatched.add('Route ${doc.id}: driverId $driverId missing');
        continue;
      }
      final d = driver.data()!;
      final currentRoute = d['assignedRouteId']?.toString() ?? '';
      if (currentRoute == doc.id) continue;
      var busId = data['busId']?.toString() ?? '';
      final busNo = data['busNo']?.toString() ?? '';
      if (busId.isEmpty && busNo.isNotEmpty) {
        busId = busesByNo[busNo]?.id ?? '';
      }
      try {
        await assign(
          driverId: driverId,
          driverName: d['name']?.toString() ?? data['driverName']?.toString() ?? '',
          driverPhone:
              d['phone']?.toString() ?? data['driverPhone']?.toString() ?? '',
          routeId: doc.id,
          busId: busId,
        );
        report.fixed.add('Route ${doc.id} linked driver $driverId');
      } catch (e) {
        report.unmatched.add('Route ${doc.id}: $e');
      }
    }

    // 3) Duties: fill missing route links
    for (final doc in dutiesSnap.docs) {
      final data = doc.data();
      if (data['status']?.toString() == 'cancelled') continue;
      final driverId = data['driverId']?.toString() ?? '';
      if (driverId.isEmpty) continue;
      var routeId = data['routeId']?.toString() ?? '';
      if (routeId.isEmpty) {
        final name = data['route']?.toString().trim().toLowerCase() ?? '';
        routeId = routesByName[name]?.id ?? '';
      }
      if (routeId.isEmpty || !routesById.containsKey(routeId)) {
        report.skipped.add('Duty ${doc.id}: could not resolve route');
        continue;
      }
      final routeData = routesById[routeId]!.data();
      if ((routeData['driverId']?.toString() ?? '').isNotEmpty) continue;

      var busId = '';
      final busNo = data['busNo']?.toString() ?? '';
      if (busNo.isNotEmpty) busId = busesByNo[busNo]?.id ?? '';

      String phone = '';
      try {
        final user = await db.collection('users').doc(driverId).get();
        phone = user.data()?['phone']?.toString() ?? '';
      } catch (_) {}

      try {
        await assign(
          driverId: driverId,
          driverName: data['driverName']?.toString() ?? '',
          driverPhone: phone,
          routeId: routeId,
          busId: busId,
        );
        report.fixed.add('Duty ${doc.id} → route $routeId driver $driverId');
      } catch (e) {
        report.unmatched.add('Duty ${doc.id}: $e');
      }
    }

    debugPrint(
      'Repair assignments fixed=${report.fixed.length} '
      'unmatched=${report.unmatched.length} skipped=${report.skipped.length}',
    );
    return report;
  }

  /// Legacy name used by Manage Routes "Sync drivers" button.
  Future<int> migrateAssignmentsFromExistingData() async {
    final r = await repairAssignments();
    return r.fixed.length;
  }

  /// Clear assignment links before deleting a route document.
  Future<void> clearBeforeRouteDelete(String routeId) async {
    final db = _db;
    if (db == null || routeId.isEmpty) return;
    final snap = await db.collection('routes').doc(routeId).get();
    final driverId = snap.data()?['driverId']?.toString() ?? '';
    if (driverId.isNotEmpty) {
      await assign(
        driverId: driverId,
        driverName: snap.data()?['driverName']?.toString() ?? '',
        driverPhone: snap.data()?['driverPhone']?.toString() ?? '',
        routeId: '',
        busId: '',
      );
    }
  }

  /// Clear assignment links before deleting a bus document.
  Future<void> clearBeforeBusDelete(String busId) async {
    final db = _db;
    if (db == null || busId.isEmpty) return;
    final snap = await db.collection('buses').doc(busId).get();
    final driverId = snap.data()?['assignedDriverId']?.toString() ?? '';
    if (driverId.isEmpty) return;
    final driver = await db.collection('users').doc(driverId).get();
    await assign(
      driverId: driverId,
      driverName: driver.data()?['name']?.toString() ??
          snap.data()?['assignedDriverName']?.toString() ??
          '',
      driverPhone: driver.data()?['phone']?.toString() ?? '',
      routeId: driver.data()?['assignedRouteId']?.toString() ?? '',
      busId: '',
    );
  }

  /// Clear assignment links before deleting a driver user document.
  Future<void> clearBeforeDriverDelete(String driverId) async {
    if (driverId.isEmpty) return;
    final db = _db;
    if (db == null) return;
    final snap = await db.collection('users').doc(driverId).get();
    await assign(
      driverId: driverId,
      driverName: snap.data()?['name']?.toString() ?? '',
      driverPhone: snap.data()?['phone']?.toString() ?? '',
      routeId: '',
      busId: '',
    );
  }
}

class RepairReport {
  final List<String> fixed = [];
  final List<String> unmatched = [];
  final List<String> skipped = [];
}
