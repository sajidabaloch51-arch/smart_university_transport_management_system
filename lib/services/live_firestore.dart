import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../utils/perf_log.dart';

/// Shared live Firestore listener that:
/// - creates the underlying `.snapshots()` once per [key]
/// - **replays the last snapshot to every new listener** (warm-up must not
///   steal the only broadcast slot — that caused Manage Schedules/Buses/
///   Notices/Alerts to hang until UI timeout while cache already had data)
/// - hydrates from disk cache first
/// - times out if neither cache nor network produces a first event
///
/// IMPORTANT: Do **not** memoize `.map()` on this stream in providers.
/// Each caller should `.map(...)` per listen — the shared entry underneath
/// supports many simultaneous listeners (dashboard + pushed list screens).
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

  /// Shared broadcast of raw snapshots. Safe for many listeners.
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

  /// Convenience: shared snapshots + per-call map (do not cache the result).
  static Stream<T> mapSnapshots<T>(
    String key,
    Query<Map<String, dynamic>> Function(FirebaseFirestore db) buildQuery,
    T Function(QuerySnapshot<Map<String, dynamic>> snap) convert, {
    String? collectionLabel,
  }) {
    return snapshots(
      key,
      buildQuery,
      collectionLabel: collectionLabel,
    ).map(convert);
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

  static Future<void> forceRefresh(String key) async {
    final entry = _entries[key];
    if (entry == null) return;
    await entry.refreshFromNetwork();
  }

  /// Warm Admin collections after login without blocking the UI frame.
  ///
  /// Priority lists (drivers / routes / buses / duties) start first.
  /// Secondary lists are staggered so a slow network is not saturated.
  static void warmAdminLists() {
    if (db == null) return;
    // Never do Firestore subscribe work on the login/navigation frame.
    scheduleMicrotask(() {
      // ignore: discarded_futures
      _warmAdminListsImpl();
    });
  }

  static void _touch(
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

  static Future<void> _warmAdminListsImpl() async {
    if (db == null) return;

    // Phase 1 — dashboard essentials (cache hydrate + live listen).
    _touch(
      'users_drivers',
      (db) => db.collection('users').where('role', isEqualTo: 'driver'),
      'users(role=driver)',
    );
    _touch('routes_all', (db) => db.collection('routes'), 'routes');
    _touch('buses_all', (db) => db.collection('buses').limit(50), 'buses');
    _touch('duties_all', (db) => db.collection('duties').limit(100), 'duties');

    // Phase 2 — secondary screens, after a short delay.
    // Longer delay so phase-1 listeners settle before competing for bandwidth.
    await Future<void>.delayed(const Duration(seconds: 4));
    if (db == null) return;
    _touch(
      'users_students',
      (db) => db.collection('users').where('role', isEqualTo: 'student'),
      'users(role=student)',
    );
    _touch(
      'users_students_pending',
      (db) => db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('verificationStatus', isEqualTo: 'pending'),
      'users(student,pending)',
    );
    _touch(
      'schedules_all',
      (db) => db.collection('schedules').limit(50),
      'schedules',
    );
    _touch(
      'notices_all',
      (db) =>
          db.collection('notices').orderBy('date', descending: true).limit(50),
      'notices',
    );
    _touch('alerts_all', (db) => db.collection('alerts').limit(50), 'alerts');
  }
}

class _LiveEntry {
  _LiveEntry({
    required this.key,
    required this.collectionLabel,
    required this.buildQuery,
  }) {
    // Plain broadcast — replay is handled in [stream] via Stream.multi so
    // late listeners (Manage Schedules after warm-up) always get [_last].
    _controller =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  }

  final String key;
  final String collectionLabel;
  final Query<Map<String, dynamic>> Function(FirebaseFirestore db) buildQuery;

  late final StreamController<QuerySnapshot<Map<String, dynamic>>> _controller;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  QuerySnapshot<Map<String, dynamic>>? _last;
  Object? _lastError;
  StackTrace? _lastErrorStack;
  int _listenerCount = 0;
  bool _diskHydrateStarted = false;
  Timer? _firstEventTimer;
  bool _firstEventDelivered = false;

  /// Every listen starts Firestore if needed and immediately gets [_last].
  Stream<QuerySnapshot<Map<String, dynamic>>> get stream {
    return Stream.multi((multi) {
      _listenerCount++;
      _ensureFirestoreListen();

      if (_last != null) {
        multi.add(_last!);
        LiveFirestore.log(
          key,
          collection: collectionLabel,
          count: _last!.docs.length,
          extra: 'replay_to_new_listener',
        );
      } else if (_lastError != null) {
        // Stale error with no data — retry once for this listener.
        scheduleMicrotask(() async {
          if (multi.isClosed) return;
          if (_last != null) {
            multi.add(_last!);
            return;
          }
          try {
            await refreshFromNetwork();
            if (!multi.isClosed && _last != null) multi.add(_last!);
          } catch (_) {
            if (!multi.isClosed && _last == null && _lastError != null) {
              multi.addError(_lastError!, _lastErrorStack);
            }
          }
        });
      }

      final sub = _controller.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = () {
        sub.cancel();
        _onCancel();
      };
    });
  }

  void _ensureFirestoreListen() {
    final firestore = LiveFirestore.db;
    if (firestore == null) {
      _lastError = StateError('Firestore not available. Check Firebase setup.');
      if (!_controller.isClosed) _controller.addError(_lastError!);
      return;
    }

    final query = buildQuery(firestore);

    if (_sub != null) {
      if (!_firstEventDelivered) _armFirstEventWatchdog(query);
      return;
    }

    PerfLog.start('fs_$key');
    LiveFirestore.log(key, collection: collectionLabel);

    if (!_diskHydrateStarted) {
      _diskHydrateStarted = true;
      // ignore: discarded_futures
      _hydrateFromDisk(query);
    }

    _armFirstEventWatchdog(query);

    _sub = query.snapshots(includeMetadataChanges: false).listen(
      (snap) {
        _emit(snap);
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
      },
      onError: (Object e, StackTrace st) {
        LiveFirestore.log(key, collection: collectionLabel, error: e);
        PerfLog.end('fs_$key', label: 'error');
        _firstEventTimer?.cancel();
        _lastError = e;
        _lastErrorStack = st;
        if (!_controller.isClosed) _controller.addError(e, st);
      },
    );
  }

  void _emit(QuerySnapshot<Map<String, dynamic>> snap) {
    _last = snap;
    _lastError = null;
    _lastErrorStack = null;
    _firstEventDelivered = true;
    _firstEventTimer?.cancel();
    if (!_controller.isClosed) _controller.add(snap);
  }

  /// If cache is empty and the network is slow, nudge with a one-shot get.
  /// Must stay longer than a cold DNS/TLS handshake — the old 2s+4s window
  /// raced the UI's 5s timer and poisoned secondary Admin lists.
  void _armFirstEventWatchdog(Query<Map<String, dynamic>> query) {
    _firstEventTimer?.cancel();
    if (_firstEventDelivered || _last != null) return;
    _firstEventTimer = Timer(const Duration(seconds: 8), () async {
      if (_firstEventDelivered || _last != null || _controller.isClosed) return;
      LiveFirestore.log(
        key,
        collection: collectionLabel,
        extra: 'first_event_watchdog',
      );
      try {
        QuerySnapshot<Map<String, dynamic>>? snap;
        try {
          snap = await query
              .get(const GetOptions(source: Source.cache))
              .timeout(const Duration(milliseconds: 500));
        } catch (_) {}
        // Empty cache is normal — still try serverAndCache (never Source.server).
        if (!_firstEventDelivered && !_controller.isClosed) {
          final needsServer = snap == null || snap.docs.isEmpty;
          if (needsServer) {
            snap = await query
                .get(const GetOptions(source: Source.serverAndCache))
                .timeout(const Duration(seconds: 12));
          }
        }
        if (_firstEventDelivered || _controller.isClosed || snap == null) {
          return;
        }
        // Empty list is valid data — emit so UI shows empty state, not timeout.
        PerfLog.mark('fs_$key', 'watchdog_get', count: snap.docs.length);
        _emit(snap);
      } catch (e, st) {
        if (_firstEventDelivered || _last != null || _controller.isClosed) {
          return;
        }
        LiveFirestore.log(key, collection: collectionLabel, error: e);
        debugPrint(
          '🔥 LiveFirestore watchdog $key real error '
          'type=${e.runtimeType} error=$e\n$st',
        );
        PerfLog.end('fs_$key', label: 'watchdog_timeout');
        // Preserve the real exception — do NOT rewrite as a fake network message.
        _lastError = e;
        _lastErrorStack = st;
        if (!_controller.isClosed) _controller.addError(e, st);
      }
    });
  }

  Future<void> _hydrateFromDisk(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      final snap = await query
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 400));
      if (snap.docs.isEmpty) return;
      if (_firstEventDelivered && _last != null) return;
      PerfLog.mark('fs_$key', 'disk_cache', count: snap.docs.length);
      LiveFirestore.log(
        key,
        collection: collectionLabel,
        count: snap.docs.length,
        extra: 'diskCacheHit',
      );
      _emit(snap);
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
          .timeout(const Duration(seconds: 15));
      PerfLog.mark('fs_$key', 'pull_refresh', count: snap.docs.length);
      _emit(snap);
    } catch (e, st) {
      LiveFirestore.log(key, collection: collectionLabel, error: e);
      debugPrint(
        '🔥 LiveFirestore.refresh $key type=${e.runtimeType} error=$e\n$st',
      );
      _lastError = e;
      _lastErrorStack = st;
      if (!_controller.isClosed) _controller.addError(e, st);
      rethrow;
    }
  }

  void _onCancel() {
    _listenerCount = (_listenerCount - 1).clamp(0, 9999);
  }

  void dispose() {
    _firstEventTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    if (!_controller.isClosed) _controller.close();
  }
}
