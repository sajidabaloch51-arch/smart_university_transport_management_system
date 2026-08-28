import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

class BusProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<BusModel>> streamBuses() {
    return _db.collection('buses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addBus(BusModel bus) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('buses').doc(bus.id).set(bus.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteBus(String id) async {
    await _db.collection('buses').doc(id).delete();
  }
}
