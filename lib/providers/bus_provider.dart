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

  final List<BusModel> _mockBuses = [
    BusModel(
      id: 'b1', 
      busNumber: 'UOG-001', 
      registrationNumber: 'GW-1234',
      assignedDriverId: '',
      assignedDriverName: 'Not Assigned',
      assignedRouteId: 'r1',
      assignedRouteName: 'Route A',
      isActive: true,
    ),
    BusModel(
      id: 'b2', 
      busNumber: 'UOG-002', 
      registrationNumber: 'GW-5678',
      assignedDriverId: '',
      assignedDriverName: 'Not Assigned',
      assignedRouteId: 'r2',
      assignedRouteName: 'Route B',
      isActive: false,
    ),
  ];

  Stream<List<BusModel>> streamBuses() {
    try {
      final db = _db;
      if (db == null) return Stream.value(_mockBuses);

      return db.collection('buses')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => BusModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      debugPrint("Error in streamBuses: $e");
      return Stream.value(_mockBuses);
    }
  }

  Future<void> addBus(BusModel bus) async {
    final db = _db;
    if (db == null) {
      final index = _mockBuses.indexWhere((b) => b.id == bus.id);
      if (index != -1) {
        _mockBuses[index] = bus;
      } else {
        _mockBuses.add(bus);
      }
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    await db.collection('buses').doc(bus.id).set(bus.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteBus(String id) async {
    final db = _db;
    if (db == null) {
      _mockBuses.removeWhere((b) => b.id == id);
      notifyListeners();
      return;
    }
    await db.collection('buses').doc(id).delete();
  }
}
