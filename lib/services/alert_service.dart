import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/alert_model.dart';
import 'live_firestore.dart';

void _logFirebaseError(String where, Object error) {
  if (error is FirebaseException) {
    debugPrint(
      '🔥 $where FirebaseException code=${error.code} message=${error.message}',
    );
  } else {
    debugPrint('🔥 $where error: $error');
  }
}

void _logQueryContext(String where, String driverId) {
  String? authUid;
  String? projectId;
  try {
    authUid = FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {}
  try {
    if (Firebase.apps.isNotEmpty) {
      projectId = Firebase.app().options.projectId;
    }
  } catch (_) {}
  debugPrint(
    '🔎 $where start driverId=$driverId '
    'authUid=$authUid projectId=$projectId '
    't=${DateTime.now().toIso8601String()}',
  );
}

class AlertService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _col {
    final db = _db;
    if (db == null) return null;
    return db.collection('alerts');
  }

  static const _allKey = 'alerts_all';
  static List<AlertModel> _cachedAll = const [];
  List<AlertModel> get cachedAlerts => _cachedAll;

  Stream<List<AlertModel>> streamAllAlerts() {
    if (_col == null) {
      return Stream.error(StateError('Firestore not available for alerts'));
    }

    return LiveFirestore.mapSnapshots(
      _allKey,
      (db) => db.collection('alerts').limit(50),
      (snap) {
        final parsed = <AlertModel>[];
        for (final d in snap.docs) {
          try {
            parsed.add(AlertModel.fromMap(d.data(), d.id));
          } catch (e, st) {
            debugPrint('⚠️ Skipping bad alerts doc id=${d.id}: $e\n$st');
          }
        }
        parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cachedAll = parsed;
        return _cachedAll;
      },
      collectionLabel: 'alerts',
    ).transform(_errorLogger('AlertService.streamAllAlerts'));
  }

  Future<void> refreshAllAlerts() => LiveFirestore.forceRefresh(_allKey);

  /// Active alerts for [driverId] (+ optional Auth/legacy ids):
  ///   1) `alerts.where('target' == 'all_drivers').snapshots()`
  ///   2) `alerts.where('driverId' in ids).snapshots()`
  /// Merged in Dart. Do NOT wrap in Stream.timeout — listeners stay quiet.
  Stream<List<AlertModel>> streamDriverAlerts(
    String driverId, {
    int? limit,
    List<String> alternateDriverIds = const [],
  }) {
    final col = _col;
    if (col == null) {
      return Stream.error(StateError('Firestore not available for alerts'));
    }
    final ids = [driverId, ...alternateDriverIds]
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      debugPrint('AlertService.streamDriverAlerts skipped: empty driverId');
      return Stream.value(const []);
    }

    _logQueryContext('AlertService.streamDriverAlerts', ids.join('|'));

    final controller = StreamController<List<AlertModel>>();
    List<AlertModel> allDrivers = const [];
    List<AlertModel> specific = const [];
    var allReady = false;
    var specificReady = false;
    Object? lastError;
    StackTrace? lastStack;
    final started = DateTime.now();

    bool visibleToAny(AlertModel a) {
      if (!a.isVisibleNow) return false;
      if (a.target == 'all_drivers') return true;
      return a.target == 'specific_driver' &&
          a.driverId != null &&
          ids.contains(a.driverId);
    }

    void emit({Object? error, StackTrace? stack}) {
      if (controller.isClosed) return;
      if (error != null && allReady && specificReady) {
        controller.addError(error, stack);
        return;
      }
      final merged = <String, AlertModel>{};
      for (final a in [...allDrivers, ...specific]) {
        if (!visibleToAny(a)) continue;
        merged[a.id] = a;
      }
      var list = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (limit != null && list.length > limit) {
        list = list.take(limit).toList();
      }
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      debugPrint(
        '✅ AlertService.streamDriverAlerts emit ${elapsed}ms '
        'count=${list.length} allReady=$allReady specificReady=$specificReady',
      );
      controller.add(list);
    }

    final sub1 = col
        .where('target', isEqualTo: 'all_drivers')
        .snapshots(includeMetadataChanges: false)
        .listen(
      (snap) {
        allReady = true;
        lastError = null;
        allDrivers = snap.docs
            .map((d) => AlertModel.fromMap(d.data(), d.id))
            .toList();
        debugPrint(
          'AlertService all_drivers raw=${snap.docs.length} '
          'fromCache=${snap.metadata.isFromCache}',
        );
        emit();
      },
      onError: (e, st) {
        _logFirebaseError('AlertService.streamDriverAlerts(all_drivers)', e);
        allReady = true;
        allDrivers = const [];
        lastError = e;
        lastStack = st;
        if (specificReady) {
          emit(error: e, stack: st);
        }
      },
    );

    final specificQuery = ids.length == 1
        ? col.where('driverId', isEqualTo: ids.first)
        : col.where('driverId', whereIn: ids.take(10).toList());

    final sub2 = specificQuery.snapshots(includeMetadataChanges: false).listen(
      (snap) {
        specificReady = true;
        lastError = null;
        specific = snap.docs
            .map((d) => AlertModel.fromMap(d.data(), d.id))
            .toList();
        debugPrint(
          'AlertService specific raw=${snap.docs.length} '
          'fromCache=${snap.metadata.isFromCache}',
        );
        emit();
      },
      onError: (e, st) {
        _logFirebaseError('AlertService.streamDriverAlerts(specific)', e);
        specificReady = true;
        specific = const [];
        lastError = e;
        lastStack = st;
        if (allReady) {
          emit(error: e, stack: st);
        }
      },
    );

    controller.onCancel = () async {
      await sub1.cancel();
      await sub2.cancel();
      if (lastError != null) {
        debugPrint(
          'AlertService.streamDriverAlerts cancelled with pending error: '
          '$lastError $lastStack',
        );
      }
    };

    return controller.stream;
  }

  Future<void> saveAlert(AlertModel alert) async {
    final col = _col;
    if (col == null) throw Exception('Firestore not available.');
    await col.doc(alert.id).set(alert.toMap(), SetOptions(merge: true));
  }

  Future<void> setActive(String id, bool isActive) async {
    final col = _col;
    if (col == null) throw Exception('Firestore not available.');
    await col.doc(id).update({'isActive': isActive});
  }

  Future<void> deleteAlert(String id) async {
    final col = _col;
    if (col == null) throw Exception('Firestore not available.');
    await col.doc(id).delete();
  }
}

StreamTransformer<T, T> _errorLogger<T>(String where) {
  return StreamTransformer<T, T>.fromHandlers(
    handleData: (data, sink) => sink.add(data),
    handleError: (error, stack, sink) {
      _logFirebaseError(where, error);
      sink.addError(error, stack);
    },
  );
}
