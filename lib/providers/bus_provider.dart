import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

class BusProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Live stream from Firestore `buses` collection.
  Stream<List<BusModel>> streamBuses() {
    final db = _db;
    if (db == null) return Stream.value(const <BusModel>[]);

    return db.collection('buses').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BusModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      debugPrint('streamBuses error: $e');
    });
  }

  Future<void> addBus(BusModel bus) async {
    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    _isLoading = true;
    notifyListeners();
    try {
      await db.collection('buses').doc(bus.id).set(bus.toMap());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBus(String id) async {
    final db = _db;
    if (db == null) return;
    await db.collection('buses').doc(id).delete();
  }

  Future<void> toggleBusActive(String id) async {
    final db = _db;
    if (db == null) return;
    final doc = await db.collection('buses').doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final bus = BusModel.fromMap(doc.data()!, doc.id);
    await addBus(BusModel(
      id: bus.id,
      busNumber: bus.busNumber,
      capacity: bus.capacity,
      busModel: bus.busModel,
      registrationNumber: bus.registrationNumber,
      assignedDriverId: bus.assignedDriverId,
      assignedDriverName: bus.assignedDriverName,
      assignedRouteId: bus.assignedRouteId,
      assignedRouteName: bus.assignedRouteName,
      isActive: !bus.isActive,
    ));
  }
}
