import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../services/live_firestore.dart';

class BusProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<BusModel>>? _busesStream;
  static const _key = 'buses_all';
  List<BusModel> _cached = const [];
  List<BusModel> get cachedBuses => _cached;

  Stream<List<BusModel>> streamBuses() {
    if (_busesStream != null) return _busesStream!;
    if (LiveFirestore.db == null) return Stream.value(const <BusModel>[]);

    _busesStream = LiveFirestore.snapshots(
      _key,
      (db) => db.collection('buses'),
      collectionLabel: 'buses',
    ).map((snapshot) {
      _cached = snapshot.docs
          .map((doc) => BusModel.fromMap(doc.data(), doc.id))
          .toList();
      return _cached;
    });
    return _busesStream!;
  }

  void restartBusesStream() {
    _busesStream = null;
    LiveFirestore.restart(_key);
  }

  Future<void> refreshBuses() => LiveFirestore.forceRefresh(_key);

  Future<void> addBus(BusModel bus) async {
    final db = LiveFirestore.db;
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
    final db = LiveFirestore.db;
    if (db == null) return;
    await db.collection('buses').doc(id).delete();
  }

  Future<void> toggleBusActive(String id) async {
    final db = LiveFirestore.db;
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
