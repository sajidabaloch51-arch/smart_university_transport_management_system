import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';
import '../services/live_firestore.dart';
import '../services/route_assignment_service.dart';

class RouteProvider extends ChangeNotifier {
  static const _streamKey = 'routes_all';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RouteModel> _lastRoutes = const [];
  List<RouteModel> get cachedRoutes => _lastRoutes;

  /// Live stream from Firestore `routes` (shared broadcast + per-call map).
  /// Emits in-memory cache immediately so Admin screens never wait on network.
  Stream<List<RouteModel>> streamRoutes() {
    final live = LiveFirestore.mapSnapshots(
      _streamKey,
      (db) => db.collection('routes'),
      (snapshot) {
        // Admin + student: show every route. (Old uog-only filter hid routes
        // that were missing universityId and left Assign Route as Not Assigned.)
        final list = <RouteModel>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(RouteModel.fromMap(doc.id, doc.data()));
          } catch (e, st) {
            debugPrint('⚠️ Skipping bad route doc id=${doc.id}: $e\n$st');
          }
        }
        _lastRoutes = list;
        return list;
      },
      collectionLabel: 'routes',
    );
    final seed = _lastRoutes;
    if (seed.isEmpty) return live;
    return Stream<List<RouteModel>>.multi((controller) {
      controller.add(seed);
      final sub = live.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  void restartRoutesStream() {
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
      // Prefer uog for student UX, but never hide the full set when empty.
      final uog = all.where((r) => r.universityId == 'uog').toList();
      final list = uog.isNotEmpty ? uog : all;
      if (list.isNotEmpty) _lastRoutes = list;
      return list;
    } catch (_) {
      return _lastRoutes;
    }
  }

  /// Admin assignment dropdowns: every route doc, no university filter.
  /// Uses cache first, then server — does not depend on LiveFirestore listeners.
  Future<List<RouteModel>> fetchAllRoutesForAssignment() async {
    final db = LiveFirestore.db;
    if (db == null) return _lastRoutes;
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await db
            .collection('routes')
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 800));
      } catch (_) {
        snap = await db
            .collection('routes')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 8));
      }
      if (snap.docs.isEmpty) {
        snap = await db
            .collection('routes')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 8));
      }
      final list = snap.docs
          .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.routeName.compareTo(b.routeName));
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
    await RouteAssignmentService().clearBeforeRouteDelete(id);
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
