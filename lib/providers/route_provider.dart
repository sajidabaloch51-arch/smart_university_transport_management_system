import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {}
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<RouteModel> _mockRoutes = [];

  Stream<List<RouteModel>> streamRoutes() {
    return Stream.value(List<RouteModel>.from(_mockRoutes));
  }

  Future<void> addRoute(RouteModel route) async {
    final index = _mockRoutes.indexWhere((r) => r.id == route.id);
    if (index != -1) {
      _mockRoutes[index] = route;
    } else {
      _mockRoutes.add(route);
    }
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('routes').doc(route.id).set(route.toMap()).then(
      (_) {},
      onError: (e) => debugPrint('Error saving route: $e'),
    );
  }

  Future<void> deleteRoute(String id) async {
    _mockRoutes.removeWhere((r) => r.id == id);
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('routes').doc(id).delete().then(
      (_) {},
      onError: (e) => debugPrint('Error deleting route: $e'),
    );
  }

  Future<void> toggleRouteActive(String id) async {
    final index = _mockRoutes.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final route = _mockRoutes[index];
    await addRoute(route.copyWith(isActive: !route.isActive));
  }
}
