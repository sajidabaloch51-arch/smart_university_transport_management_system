import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint("Firestore access error: $e");
    }
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<RouteModel> _mockRoutes = [
    RouteModel(
      id: 'r1', 
      universityId: 'uog', 
      routeName: 'Gwadar East Bay', 
      routeNumber: 'A', 
      startPoint: 'City Center', 
      endPoint: 'UOG Main Campus', 
      stops: [], 
      totalDistance: '12km', 
      estimatedDuration: '30m'
    ),
  ];

  Stream<List<RouteModel>> streamRoutes() {
    final db = _db;
    if (db == null) return Stream.value(_mockRoutes);

    return db.collection('routes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addRoute(RouteModel route) async {
    final db = _db;
    if (db == null) {
      _mockRoutes.add(route);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    await db.collection('routes').doc(route.id).set(route.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRoute(String id) async {
    final db = _db;
    if (db == null) {
      _mockRoutes.removeWhere((r) => r.id == id);
      notifyListeners();
      return;
    }
    await db.collection('routes').doc(id).delete();
  }
}
