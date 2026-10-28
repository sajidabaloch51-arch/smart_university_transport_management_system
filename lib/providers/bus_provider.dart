import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../services/live_firestore.dart';
import '../services/route_assignment_service.dart';
import '../utils/firestore_parse.dart';

class BusProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static const _key = 'buses_all';
  List<BusModel> _cached = const [];
  List<BusModel> get cachedBuses => _cached;

  Stream<List<BusModel>> streamBuses() {
    if (LiveFirestore.db == null) return Stream.value(const <BusModel>[]);
    final live = LiveFirestore.mapSnapshots(
      _key,
      (db) => db.collection('buses').limit(50),
      (snapshot) {
        _cached = FirestoreParse.mapDocs(
          snapshot.docs,
          (data, id) => BusModel.fromMap(data, id),
          label: 'buses',
        );
        return _cached;
      },
      collectionLabel: 'buses',
    );
    final seed = _cached;
    if (seed.isEmpty) return live;
    return Stream<List<BusModel>>.multi((controller) {
      controller.add(seed);
      final sub = live.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  void restartBusesStream() {
    LiveFirestore.restart(_key);
  }

  Future<void> refreshBuses() => LiveFirestore.forceRefresh(_key);

  Future<List<BusModel>> loadBusesFromCache() async {
    if (_cached.isNotEmpty) return _cached;
    final db = LiveFirestore.db;
    if (db == null) return const [];
    try {
      final snap = await db
          .collection('buses')
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 500));
      if (snap.docs.isEmpty) return _cached;
      _cached = snap.docs
          .map((doc) => BusModel.fromMap(doc.data(), doc.id))
          .toList();
      return _cached;
    } catch (_) {
      return _cached;
    }
  }

  /// Admin assignment dropdowns — direct get, independent of live listeners.
  Future<List<BusModel>> fetchAllBusesForAssignment() async {
    final db = LiveFirestore.db;
    if (db == null) return _cached;
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await db
            .collection('buses')
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 800));
      } catch (_) {
        snap = await db
            .collection('buses')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 8));
      }
      if (snap.docs.isEmpty) {
        snap = await db
            .collection('buses')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 8));
      }
      _cached = snap.docs
          .map((doc) => BusModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.busNumber.compareTo(b.busNumber));
      return _cached;
    } catch (_) {
      return _cached;
    }
  }

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
      await db
          .collection('buses')
          .doc(bus.id)
          .set(bus.toMap(), SetOptions(merge: true));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBus(String id) async {
    final db = LiveFirestore.db;
    if (db == null) return;
    await RouteAssignmentService().clearBeforeBusDelete(id);
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
