import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

class BusProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {}
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<BusModel> _mockBuses = [];

  Stream<List<BusModel>> streamBuses() {
    return Stream.value(List<BusModel>.from(_mockBuses));
  }

  Future<void> addBus(BusModel bus) async {
    final index = _mockBuses.indexWhere((b) => b.id == bus.id);
    if (index != -1) {
      _mockBuses[index] = bus;
    } else {
      _mockBuses.add(bus);
    }
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('buses').doc(bus.id).set(bus.toMap()).then(
      (_) {},
      onError: (e) => debugPrint('Error saving bus: $e'),
    );
  }

  Future<void> deleteBus(String id) async {
    _mockBuses.removeWhere((b) => b.id == id);
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('buses').doc(id).delete().then(
      (_) {},
      onError: (e) => debugPrint('Error deleting bus: $e'),
    );
  }

  Future<void> toggleBusActive(String id) async {
    final index = _mockBuses.indexWhere((b) => b.id == id);
    if (index == -1) return;
    final bus = _mockBuses[index];
    await addBus(BusModel(
      id: bus.id,
      busNumber: bus.busNumber,
      registrationNumber: bus.registrationNumber,
      assignedDriverId: bus.assignedDriverId,
      assignedDriverName: bus.assignedDriverName,
      assignedRouteId: bus.assignedRouteId,
      assignedRouteName: bus.assignedRouteName,
      isActive: !bus.isActive,
    ));
  }
}
