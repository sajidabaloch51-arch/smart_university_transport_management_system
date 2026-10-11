import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/bus_live_location_model.dart';

/// Publishes / listens to live bus GPS in Firebase Realtime Database.
///
/// Structure:
/// ```
/// liveBusLocations/
///   {driverId}/
///     lat, lng, speed, heading, isOnDuty, lastUpdated,
///     driverName, busId, busNumber, routeId, routeName
/// ```
class RealtimeLocationService {
  static const String collectionPath = 'liveBusLocations';

  DatabaseReference? get _root {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseDatabase.instance.ref(collectionPath);
    } catch (e) {
      debugPrint('RealtimeLocationService: RTDB unavailable: $e');
      return null;
    }
  }

  DatabaseReference? driverRef(String driverId) {
    final root = _root;
    if (root == null || driverId.isEmpty) return null;
    return root.child(driverId);
  }

  /// Stream live location for a driver (student / admin consumers).
  Stream<BusLiveLocationModel?> watchDriverLocation(String driverId) {
    final ref = driverRef(driverId);
    if (ref == null) {
      return Stream.value(null);
    }

    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return null;
      return BusLiveLocationModel.fromMap(
        driverId,
        Map<dynamic, dynamic>.from(value),
      );
    }).handleError((e) {
      debugPrint('watchDriverLocation error: $e');
    });
  }

  /// Driver publishes GPS while trip/duty is active.
  Future<void> publishLocation(BusLiveLocationModel location) async {
    final ref = driverRef(location.driverId);
    if (ref == null) return;
    try {
      await ref.set(location.toMap());
    } catch (e) {
      debugPrint('publishLocation error: $e');
      rethrow;
    }
  }

  /// Mark driver offline when duty ends (keeps last coords).
  Future<void> markOffline(String driverId) async {
    final ref = driverRef(driverId);
    if (ref == null) return;
    try {
      await ref.update({
        'isOnDuty': false,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('markOffline error: $e');
    }
  }
}
