import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../utils/perf_log.dart';

/// Shared live Firestore listener that:
/// - creates the underlying `.snapshots()` once per [key]
/// - keeps a broadcast controller that re-emits the last snapshot
/// - hydrates from **disk cache first** so lists paint in <100ms on repeat visits
class LiveFirestore {
  LiveFirestore._();

  static final Map<String, _LiveEntry> _entries = {};

  static FirebaseFirestore? get db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  static String get projectId {
    try {
      if (Firebase.apps.isNotEmpty) {
        return Firebase.app().options.projectId;
      }
    } catch (_) {}
    return '?';
  }

  static String? get authUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static void log(
    String where, {
    String? collection,
    Object? error,
    int? count,
    String? extra,
  }) {
    final auth = authUid ?? 'null';
    final base =
        '🔎 FS[$where] project=$projectId authUid=$auth collection=${collection ?? '-'}';
    if (error != null) {
      if (error is FirebaseException) {
        debugPrint(
          '$base ERROR code=${error.code} message=${error.message} $extra',
        );
      } else {
        debugPrint('$base ERROR $error $extra');
      }
    } else if (count != null) {
      debugPrint('$base ok count=$count $extra');
    } else {
      debugPrint('$base start $extra');
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
    String key,
    Query<Map<String, dynamic>> Function(FirebaseFirestore db) buildQuery, {
    String? collectionLabel,
  }) {
    final firestore = db;
    if (firestore == null) {
      return Stream.error(
        StateError('Firestore not available. Check Firebase setup.'),
      );
    }

    var entry = _entries[key];
    if (entry == null) {
      entry = _LiveEntry(
        key: key,
        collectionLabel: collectionLabel ?? key,
        buildQuery: buildQuery,
      );
      _entries[key] = entry;
    }
    return entry.stream;
  }

  static void restart(String key) {
    final entry = _entries.remove(key);
    entry?.dispose();
  }

  static void restartAll() {
    for (final e in _entries.values.toList()) {
      e.dispose();
    }
    _entries.clear();
  }

  /// Push a fresh server+cache read into an existing live entry (pull-to-refresh).
  static Future<void> forceRefresh(String key) async {
    final entry = _entries[key];
    if (entry == null) return;
    await entry.refreshFromNetwork();
  }

  /// Warm common Admin collections after login (non-blocking).
  static void warmAdminLists() {
    if (db == null) return;
    void touch(
      String key,
      Query<Map<String, dynamic>> Function(FirebaseFirestore db) q,
      String label,
    ) {
      snapshots(key, q, collectionLabel: label).listen(
        (_) {},
        onError: (_) {},
        cancelOnError: false,
      );
    }

    touch(
      'users_drivers',
      (db) => db.collection('users').where('role', isEqualTo: 'driver'),
      'users(role=driver)',
    );
    touch(
      'users_students',
      (db) => db.collection('users').where('role', isEqualTo: 'student'),
      'users(role=student)',
    );
    touch(
      'users_students_pending',
      (db) => db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('verificationStatus', isEqualTo: 'pending'),
      'users(student,pending)',
    );
    touch('routes_all', (db) => db.collection('routes'), 'routes');
    touch('schedules_all', (db) => db.collection('schedules'), 'schedules');
    touch('buses_all', (db) => db.collection('buses'), 'buses');
    touch(
      'notices_all',
      (db) =>
          db.collection('notices').orderBy('date', descending: true).limit(50),
      'notices',
    );
    touch('duties_all', (db) => db.collection('duties').limit(100), 'duties');
    touch('alerts_all', (db) => db.collection('alerts').limit(100), 'alerts');
  }
}

class _LiveEntry {
  _LiveEntry({
    required this.key,
    required this.collectionLabel,
    required this.buildQuery,
  }) {
    _controller =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast(
      onListen: _ensureSubscribed,
      onCancel: _onCancel,
    );
  }

  final String key;
  final String collectionLabel;
  final Query<Map<String, dynamic>> Function(FirebaseFirestore db) buildQuery;

  late final StreamController<QuerySnapshot<Map<String, dynamic>>> _controller;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  QuerySnapshot<Map<String, dynamic>>? _last;
  int _listenerCount = 0;
  bool _diskHydrateStarted = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> get stream => _controller.stream;

  void _ensureSubscribed() {
    _listenerCount++;
    if (_last != null && !_controller.isClosed) {
      scheduleMicrotask(() {
        if (!_controller.isClosed && _last != null) {
          _controller.add(_last!);
        }
      });
    }
    if (_sub != null) return;

    final firestore = LiveFirestore.db;
    if (firestore == null) {
      _controller.addError(
        StateError('Firestore not available. Check Firebase setup.'),
      );
      return;
    }

    final query = buildQuery(firestore);
    PerfLog.start('fs_$key');
    LiveFirestore.log(key, collection: collectionLabel);

    // Disk cache first — paints lists before the network returns.
    if (!_diskHydrateStarted) {
      _diskHydrateStarted = true;
      // ignore: discarded_futures
      _hydrateFromDisk(query);
    }

    _sub = query.snapshots(includeMetadataChanges: false).listen(
      (snap) {
        _last = snap;
        final fromCache = snap.metadata.isFromCache;
        PerfLog.mark(
          'fs_$key',
          fromCache ? 'snapshot_cache' : 'snapshot_server',
          count: snap.docs.length,
        );
        if (!fromCache) {
          PerfLog.end(
            'fs_$key',
            label: 'first_server',
            count: snap.docs.length,
          );
        }
        LiveFirestore.log(
          key,
          collection: collectionLabel,
          count: snap.docs.length,
          extra: fromCache ? 'fromCache' : 'fromServer',
        );
        if (!_controller.isClosed) _controller.add(snap);
      },
      onError: (Object e, StackTrace st) {
        LiveFirestore.log(key, collection: collectionLabel, error: e);
        PerfLog.end('fs_$key', label: 'error');
        if (!_controller.isClosed) _controller.addError(e, st);
      },
    );
  }

  Future<void> _hydrateFromDisk(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      final snap = await query
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 600));
      if (snap.docs.isEmpty) return;
      _last = snap;
      PerfLog.mark('fs_$key', 'disk_cache', count: snap.docs.length);
      LiveFirestore.log(
        key,
        collection: collectionLabel,
        count: snap.docs.length,
        extra: 'diskCacheHit',
      );
      if (!_controller.isClosed) _controller.add(snap);
    } catch (_) {
      // Cache miss is normal on first install.
    }
  }

  Future<void> refreshFromNetwork() async {
    final firestore = LiveFirestore.db;
    if (firestore == null) return;
    try {
      final snap = await buildQuery(firestore)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 10));
      _last = snap;
      PerfLog.mark('fs_$key', 'pull_refresh', count: snap.docs.length);
      if (!_controller.isClosed) _controller.add(snap);
    } catch (e, st) {
      LiveFirestore.log(key, collection: collectionLabel, error: e);
      if (!_controller.isClosed) _controller.addError(e, st);
    }
  }

  void _onCancel() {
    _listenerCount = (_listenerCount - 1).clamp(0, 9999);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    if (!_controller.isClosed) _controller.close();
  }
}
