import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/duty_model.dart';
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

class DutyService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  CollectionReference<Map<String, dynamic>>? get _col {
    final db = _db;
    if (db == null) return null;
    return db.collection('duties');
  }

  static const _allKey = 'duties_all';
  static List<DutyModel> _cachedAll = const [];
  List<DutyModel> get cachedDuties => _cachedAll;
  static Stream<List<DutyModel>>? _allStream;

  Stream<List<DutyModel>> streamAllDuties() {
    if (_allStream != null) return _allStream!;
    if (_col == null) {
      return Stream.error(
        StateError('Firestore not available for duties'),
      );
    }

    _allStream = LiveFirestore.snapshots(
      _allKey,
      (db) => db.collection('duties').limit(100),
      collectionLabel: 'duties',
    ).map((snap) {
      _cachedAll = snap.docs
          .map((d) => DutyModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.shiftStart.compareTo(a.shiftStart));
      return _cachedAll;
    }).transform(_errorLogger('DutyService.streamAllDuties'));
    return _allStream!;
  }

  Future<void> refreshAllDuties() => LiveFirestore.forceRefresh(_allKey);

  /// Builds a driverId query. Uses `whereIn` when Auth uid ≠ Firestore doc id.
  Query<Map<String, dynamic>> _driverIdQuery(
    CollectionReference<Map<String, dynamic>> col,
    List<String> driverIds,
  ) {
    final ids = driverIds.where((e) => e.isNotEmpty).toSet().toList();
    if (ids.length == 1) {
      return col.where('driverId', isEqualTo: ids.first);
    }
    return col.where('driverId', whereIn: ids.take(10).toList());
  }

  /// Today's duties for one or more identity keys (Auth uid + users doc id).
  /// Do NOT wrap in Stream.timeout — live listeners stay quiet between updates.
  Stream<List<DutyModel>> streamTodayDuties({
    required String driverId,
    required String dutyDate,
    List<String> alternateDriverIds = const [],
  }) {
    final col = _col;
    if (col == null) {
      return Stream.error(
        StateError('Firestore not available for duties'),
      );
    }
    final ids = [driverId, ...alternateDriverIds]
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      debugPrint('DutyService.streamTodayDuties skipped: empty driverId');
      return Stream.value(const []);
    }

    _logQueryContext('DutyService.streamTodayDuties', ids.join('|'));
    debugPrint('DutyService.streamTodayDuties dutyDate=$dutyDate ids=$ids');

    final started = DateTime.now();
    return _driverIdQuery(col, ids)
        .snapshots(includeMetadataChanges: false)
        .map((snap) {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final list = snap.docs
          .map((d) => DutyModel.fromMap(d.data(), d.id))
          .where((d) => d.dutyDate == dutyDate && d.status != 'cancelled')
          .toList()
        ..sort((a, b) => a.shiftStart.compareTo(b.shiftStart));
      debugPrint(
        '✅ DutyService.streamTodayDuties finish ${elapsed}ms '
        'raw=${snap.docs.length} filtered=${list.length} '
        'fromCache=${snap.metadata.isFromCache}',
      );
      return list;
    }).transform(_errorLogger('DutyService.streamTodayDuties'));
  }

  Stream<List<DutyModel>> streamDriverDuties(
    String driverId, {
    List<String> alternateDriverIds = const [],
  }) {
    final col = _col;
    if (col == null) {
      return Stream.error(
        StateError('Firestore not available for duties'),
      );
    }
    final ids = [driverId, ...alternateDriverIds]
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      debugPrint('DutyService.streamDriverDuties skipped: empty driverId');
      return Stream.value(const []);
    }

    _logQueryContext('DutyService.streamDriverDuties', ids.join('|'));
    final started = DateTime.now();

    return _driverIdQuery(col, ids)
        .snapshots(includeMetadataChanges: false)
        .map((snap) {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final list = snap.docs
          .map((d) => DutyModel.fromMap(d.data(), d.id))
          .where((d) => d.status != 'cancelled')
          .toList()
        ..sort((a, b) => b.shiftStart.compareTo(a.shiftStart));
      debugPrint(
        '✅ DutyService.streamDriverDuties finish ${elapsed}ms '
        'count=${list.length} fromCache=${snap.metadata.isFromCache}',
      );
      return list;
    }).transform(_errorLogger('DutyService.streamDriverDuties'));
  }

  Future<List<DutyModel>> getDutiesForDriverOnDate({
    required String driverId,
    required String dutyDate,
  }) async {
    final col = _col;
    if (col == null) return const [];

    try {
      // Default source (cache + server) — never Source.server-only.
      final snap = await col.where('driverId', isEqualTo: driverId).get();

      return snap.docs
          .map((d) => DutyModel.fromMap(d.data(), d.id))
          .where((d) => d.dutyDate == dutyDate && d.status != 'cancelled')
          .toList();
    } catch (e) {
      _logFirebaseError('DutyService.getDutiesForDriverOnDate', e);
      rethrow;
    }
  }

  Future<void> saveDuty(DutyModel duty) async {
    final col = _col;
    if (col == null) throw Exception('Firestore not available.');
    debugPrint(
      'DutyService.saveDuty id=${duty.id} driverId=${duty.driverId} '
      'dutyDate=${duty.dutyDate}',
    );
    await col.doc(duty.id).set(duty.toMap(), SetOptions(merge: true));
  }

  Future<void> updateStatus(String id, String status) async {
    final col = _col;
    if (col == null) throw Exception('Firestore not available.');
    await col.doc(id).update({'status': status});
  }

  Future<void> deleteDuty(String id) async {
    final col = _col;
    if (col == null) throw Exception('Firestore not available.');
    await col.doc(id).delete();
  }

  Future<String?> findOverlapConflict(DutyModel candidate) async {
    final existing = await getDutiesForDriverOnDate(
      driverId: candidate.driverId,
      dutyDate: candidate.dutyDate,
    );

    for (final other in existing) {
      if (other.id == candidate.id) continue;
      if (DutyModel.overlaps(
        candidate.shiftStart,
        candidate.shiftEnd,
        other.shiftStart,
        other.shiftEnd,
      )) {
        return 'This driver already has a duty overlapping '
            '${other.busNo} / ${other.route} on ${other.dutyDate}.';
      }
    }
    return null;
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
