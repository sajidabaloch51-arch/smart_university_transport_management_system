import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/gps_location_model.dart';
import '../models/trip_model.dart';
import '../utils/firestore_parse.dart';

class TripStartException implements Exception {
  final String message;
  TripStartException(this.message);
  @override
  String toString() => message;
}

/// Firestore-backed trips + gps_locations (no RTDB, no paid maps).
class TripTrackingService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _trips =>
      _db?.collection('trips');

  CollectionReference<Map<String, dynamic>>? get _gps =>
      _db?.collection('gps_locations');

  /// Pure gate used by unit tests and startTrip.
  static void assertCanStartTrip({
    required String? verificationStatus,
    required String? busId,
    required String? routeId,
  }) {
    final status = (verificationStatus ?? '').trim().toLowerCase();
    if (status != 'approved') {
      throw TripStartException(
        'Your driver account is not approved yet. Contact Admin.',
      );
    }
    if (busId == null || busId.trim().isEmpty ||
        busId.toLowerCase() == 'not assigned') {
      throw TripStartException('No bus assigned. Ask Admin to assign a bus.');
    }
    if (routeId == null ||
        routeId.trim().isEmpty ||
        routeId.toLowerCase() == 'not assigned') {
      throw TripStartException(
        'No route assigned. Ask Admin to assign a route.',
      );
    }
  }

  Future<String> startTrip({
    required String driverId,
    required String driverName,
    required String busId,
    required String busNumber,
    required String routeId,
    required String routeName,
    required String? verificationStatus,
  }) async {
    assertCanStartTrip(
      verificationStatus: verificationStatus,
      busId: busId,
      routeId: routeId,
    );
    final trips = _trips;
    final gps = _gps;
    if (trips == null || gps == null) {
      throw TripStartException('Firestore is unavailable. Check connection.');
    }

    // End any leftover ACTIVE trips for this driver.
    final existing = await trips
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'ACTIVE')
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {
        'status': 'COMPLETED',
        'endTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        gps.doc(doc.id),
        {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }

    final ref = trips.doc();
    batch.set(ref, {
      'busId': busId,
      'driverId': driverId,
      'routeId': routeId,
      'busNumber': busNumber,
      'routeName': routeName,
      'driverName': driverName,
      'status': 'ACTIVE',
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(gps.doc(ref.id), {
      'tripId': ref.id,
      'busId': busId,
      'driverId': driverId,
      'latitude': 0,
      'longitude': 0,
      'speed': 0,
      'heading': 0,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  Future<void> endTrip(String tripId, {String? driverId}) async {
    final trips = _trips;
    final gps = _gps;
    if (trips == null || gps == null || tripId.isEmpty) return;

    final snap = await trips.doc(tripId).get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    if (driverId != null &&
        driverId.isNotEmpty &&
        FirestoreParse.asString(data['driverId']) != driverId) {
      throw TripStartException('You can only end your own trip.');
    }

    await trips.doc(tripId).set({
      'status': 'COMPLETED',
      'endTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await gps.doc(tripId).set({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  double? _lastLat;
  double? _lastLng;
  DateTime? _lastWrite;

  /// Upsert GPS; skips near-duplicates (<3s and ~same coords).
  Future<void> upsertGps({
    required String tripId,
    required String busId,
    required String driverId,
    required double latitude,
    required double longitude,
    double speed = 0,
    double heading = 0,
  }) async {
    final gps = _gps;
    final trips = _trips;
    if (gps == null || trips == null || tripId.isEmpty) return;

    final now = DateTime.now();
    if (_lastWrite != null &&
        now.difference(_lastWrite!).inSeconds < 3 &&
        _lastLat != null &&
        _lastLng != null) {
      final dLat = (latitude - _lastLat!).abs();
      final dLng = (longitude - _lastLng!).abs();
      if (dLat < 0.00005 && dLng < 0.00005) return;
    }

    _lastLat = latitude;
    _lastLng = longitude;
    _lastWrite = now;

    try {
      await gps.doc(tripId).set({
        'tripId': tripId,
        'busId': busId,
        'driverId': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await trips.doc(tripId).set({
        'lastLat': latitude,
        'lastLng': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('upsertGps failed: $e');
      rethrow;
    }
  }

  void resetDedupe() {
    _lastLat = null;
    _lastLng = null;
    _lastWrite = null;
  }

  Stream<List<TripModel>> watchActiveTrips() {
    final trips = _trips;
    if (trips == null) return Stream.value(const []);
    return trips
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TripModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        final at = a.updatedAt ?? a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.updatedAt ?? b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Stream<TripModel?> watchActiveTripForDriver(String driverId) {
    final trips = _trips;
    if (trips == null || driverId.isEmpty) return Stream.value(null);
    return trips
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'ACTIVE')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return TripModel.fromMap(d.data(), d.id);
    });
  }

  Stream<TripModel?> watchActiveTripForRoute(String routeId) {
    final trips = _trips;
    if (trips == null || routeId.isEmpty) return Stream.value(null);
    return trips
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: 'ACTIVE')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return TripModel.fromMap(d.data(), d.id);
    });
  }

  Stream<TripModel?> watchActiveTripForBus(String busId) {
    final trips = _trips;
    if (trips == null || busId.isEmpty) return Stream.value(null);
    return trips
        .where('busId', isEqualTo: busId)
        .where('status', isEqualTo: 'ACTIVE')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return TripModel.fromMap(d.data(), d.id);
    });
  }

  Stream<GpsLocationModel?> watchTripGps(String tripId) {
    final gps = _gps;
    if (gps == null || tripId.isEmpty) return Stream.value(null);
    return gps.doc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GpsLocationModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<bool> routeHasActiveTrip(String routeId) async {
    final trips = _trips;
    if (trips == null || routeId.isEmpty) return false;
    final snap = await trips
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: 'ACTIVE')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
