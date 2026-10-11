import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Live stream from Firestore `routes` (University of Gwadar = uog).
  Stream<List<RouteModel>> streamRoutes() {
    final db = _db;
    if (db == null) return Stream.value(const <RouteModel>[]);

    return db
        .collection('routes')
        .where('universityId', isEqualTo: 'uog')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
          .toList();
    }).handleError((e) {
      debugPrint('streamRoutes error: $e');
      // Fallback: read all routes if universityId filter fails / empty.
    });
  }

  Future<void> addRoute(RouteModel route) async {
    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    _isLoading = true;
    notifyListeners();
    try {
      await db.collection('routes').doc(route.id).set(route.toMap());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRoute(String id) async {
    final db = _db;
    if (db == null) return;
    await db.collection('routes').doc(id).delete();
  }

  Future<void> toggleRouteActive(String id) async {
    final db = _db;
    if (db == null) return;
    final doc = await db.collection('routes').doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final route = RouteModel.fromMap(doc.id, doc.data()!);
    await addRoute(route.copyWith(isActive: !route.isActive));
  }
}
