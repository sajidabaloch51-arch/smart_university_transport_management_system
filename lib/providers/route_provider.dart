import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';
import '../services/live_firestore.dart';

class RouteProvider extends ChangeNotifier {
  static const _streamKey = 'routes_all';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RouteModel> _lastRoutes = const [];
  List<RouteModel> get cachedRoutes => _lastRoutes;

  Stream<List<RouteModel>>? _mapped;

  /// Live stream from Firestore `routes` (shared, re-subscribable).
  Stream<List<RouteModel>> streamRoutes() {
    if (_mapped != null) return _mapped!;
    _mapped = LiveFirestore.snapshots(
      _streamKey,
      (db) => db.collection('routes'),
      collectionLabel: 'routes',
    ).map((snapshot) {
      final all = snapshot.docs
          .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
          .toList();
      final uog = all.where((r) => r.universityId == 'uog').toList();
      final list = uog.isNotEmpty ? uog : all;
      _lastRoutes = list;
      return list;
    });
    return _mapped!;
  }

  void restartRoutesStream() {
    _mapped = null;
    LiveFirestore.restart(_streamKey);
    notifyListeners();
  }

  Future<void> refreshRoutes() => LiveFirestore.forceRefresh(_streamKey);

  Future<List<RouteModel>> loadRoutesFromCache() async {
    if (_lastRoutes.isNotEmpty) return _lastRoutes;
    final db = LiveFirestore.db;
    if (db == null) return const [];
    try {
      final snap = await db
          .collection('routes')
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 500));
      final all = snap.docs
          .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
          .toList();
      final uog = all.where((r) => r.universityId == 'uog').toList();
      final list = uog.isNotEmpty ? uog : all;
      if (list.isNotEmpty) _lastRoutes = list;
      return list;
    } catch (_) {
      return _lastRoutes;
    }
  }

  Future<void> addRoute(RouteModel route) async {
    final db = LiveFirestore.db;
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
    final db = LiveFirestore.db;
    if (db == null) return;
    await db.collection('routes').doc(id).delete();
  }

  Future<void> toggleRouteActive(String id) async {
    final db = LiveFirestore.db;
    if (db == null) return;
    final doc = await db.collection('routes').doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final route = RouteModel.fromMap(doc.id, doc.data()!);
    await addRoute(route.copyWith(isActive: !route.isActive));
  }
}
