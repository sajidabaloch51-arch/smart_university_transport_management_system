import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/notice_model.dart';
import '../services/live_firestore.dart';
import '../utils/firestore_parse.dart';

class NoticeProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NoticeModel> _cache = [];
  List<NoticeModel> get notices => List.unmodifiable(_cache);
  List<NoticeModel> get cachedNotices => List.unmodifiable(_cache);

  static const _key = 'notices_all';

  /// Admin list — all notices, newest first (uses legacy `date` for compat).
  Stream<List<NoticeModel>> streamNotices() {
    if (LiveFirestore.db == null) {
      return Stream.value(const <NoticeModel>[]);
    }
    final live = LiveFirestore.mapSnapshots(
      _key,
      (db) =>
          db.collection('notices').orderBy('date', descending: true).limit(100),
      (snapshot) {
        _cache = _parseDocs(snapshot.docs);
        return _cache;
      },
      collectionLabel: 'notices',
    );
    return _withSeed(live, _cache);
  }

  /// Active notices for students (audience all | students).
  Stream<List<NoticeModel>> streamNoticesForStudents({int? limit}) {
    return _roleStream(
      key: 'notices_role_students',
      role: 'student',
      audiences: const ['all', 'students'],
      limit: limit,
    );
  }

  /// Active notices for a driver.
  Stream<List<NoticeModel>> streamNoticesForDriver(
    String driverId, {
    List<String> alternateDriverIds = const [],
    int? limit,
  }) {
    final ids = [driverId, ...alternateDriverIds]
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    return _roleStream(
      key: 'notices_role_driver_${ids.join('|')}_$limit',
      role: 'driver',
      audiences: const ['all', 'drivers'],
      driverIds: ids,
      limit: limit,
    );
  }

  Stream<List<NoticeModel>> _roleStream({
    required String key,
    required String role,
    required List<String> audiences,
    List<String> driverIds = const [],
    int? limit,
  }) {
    if (LiveFirestore.db == null) {
      return Stream.value(const <NoticeModel>[]);
    }

    final live = LiveFirestore.mapSnapshots(
      key,
      (db) => db
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .where('audience', whereIn: audiences)
          .orderBy('createdAt', descending: true)
          .limit(50),
      (snapshot) {
        var list = _parseDocs(snapshot.docs)
            .where(
              (n) => n.isVisibleTo(
                role,
                driverUid: driverIds.isEmpty ? null : driverIds.first,
              ),
            )
            .where((n) {
              if (!n.isVisibleNow) return false;
              if (role != 'driver') return true;
              if (n.targetDriverId == null || n.targetDriverId!.isEmpty) {
                return true;
              }
              return driverIds.contains(n.targetDriverId);
            })
            .toList();
        if (limit != null && list.length > limit) {
          list = list.take(limit).toList();
        }
        return list;
      },
      collectionLabel: 'notices($role)',
    );

    // Until backfill, also filter the admin-style date stream in-process when
    // the signed-in user can still read those docs (audience default "all").
    final legacy = streamNotices().map((all) {
      var list = all
          .where(
            (n) => n.isVisibleTo(
              role,
              driverUid: driverIds.isEmpty ? null : driverIds.first,
            ),
          )
          .where((n) {
            if (!n.isVisibleNow) return false;
            if (role != 'driver') return true;
            if (n.targetDriverId == null || n.targetDriverId!.isEmpty) {
              return true;
            }
            return driverIds.contains(n.targetDriverId);
          })
          .toList();
      if (limit != null && list.length > limit) {
        list = list.take(limit).toList();
      }
      return list;
    });

    return Stream<List<NoticeModel>>.multi((controller) {
      List<NoticeModel> a = const [];
      List<NoticeModel> b = const [];
      var aReady = false;
      var bReady = false;

      void emit() {
        final merged = <String, NoticeModel>{};
        for (final n in [...a, ...b]) {
          merged[n.id] = n;
        }
        var list = merged.values.toList()
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
        if (limit != null && list.length > limit) {
          list = list.take(limit).toList();
        }
        controller.add(list);
      }

      final sub1 = live.listen(
        (v) {
          aReady = true;
          a = v;
          emit();
        },
        onError: (_) {
          aReady = true;
          a = const [];
          if (bReady) emit();
        },
      );
      final sub2 = legacy.listen(
        (v) {
          bReady = true;
          b = v;
          emit();
        },
        onError: (_) {
          bReady = true;
          b = const [];
          if (aReady) emit();
        },
      );
      controller.onCancel = () async {
        await sub1.cancel();
        await sub2.cancel();
      };
    });
  }

  Stream<List<NoticeModel>> streamNoticesForRole(String role) {
    if (role == 'student') return streamNoticesForStudents();
    if (role == 'driver') return streamNoticesForDriver('');
    return streamNotices();
  }

  List<NoticeModel> noticesForRole(String role, {String? driverUid}) {
    return _cache
        .where((n) => n.isVisibleTo(role, driverUid: driverUid))
        .toList();
  }

  void restartNoticesStream() => LiveFirestore.restart(_key);

  Future<void> refreshNotices() => LiveFirestore.forceRefresh(_key);

  Future<void> addNotice(NoticeModel notice) async {
    final db = LiveFirestore.db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    _isLoading = true;
    notifyListeners();
    try {
      await db.collection('notices').doc(notice.id).set(notice.toMap());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActive(String id, bool isActive) async {
    final db = LiveFirestore.db;
    if (db == null) return;
    await db.collection('notices').doc(id).update({'isActive': isActive});
  }

  Future<void> deleteNotice(String id) async {
    final db = LiveFirestore.db;
    if (db == null) return;
    await db.collection('notices').doc(id).delete();
  }

  /// Backfill legacy notices + copy `alerts` → `notices` (does not delete alerts).
  Future<({int noticesBackfilled, int alertsCopied, int alertsSkipped})>
      migrateAlertsToNotices() async {
    final db = LiveFirestore.db;
    if (db == null) throw Exception('Firestore not available.');

    var noticesBackfilled = 0;
    var alertsCopied = 0;
    var alertsSkipped = 0;

    final noticesSnap = await db.collection('notices').get();
    WriteBatch batch = db.batch();
    var ops = 0;

    Future<void> flush() async {
      if (ops == 0) return;
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }

    for (final doc in noticesSnap.docs) {
      final data = doc.data();
      final needs = !data.containsKey('audience') ||
          !data.containsKey('priority') ||
          !data.containsKey('isActive') ||
          !data.containsKey('createdAt') ||
          !data.containsKey('message');
      if (!needs) continue;
      batch.set(
        doc.reference,
        NoticeModel.fromMap(data, doc.id).toMap(),
        SetOptions(merge: true),
      );
      noticesBackfilled++;
      ops++;
      if (ops >= 400) await flush();
    }
    await flush();

    QuerySnapshot<Map<String, dynamic>> alertsSnap;
    try {
      alertsSnap = await db.collection('alerts').get();
    } catch (_) {
      return (
        noticesBackfilled: noticesBackfilled,
        alertsCopied: 0,
        alertsSkipped: 0,
      );
    }

    if (alertsSnap.docs.isEmpty) {
      await refreshNotices();
      return (
        noticesBackfilled: noticesBackfilled,
        alertsCopied: 0,
        alertsSkipped: 0,
      );
    }

    final existingIds = noticesSnap.docs.map((d) => d.id).toSet();

    for (final doc in alertsSnap.docs) {
      final data = doc.data();
      final noticeId = 'alert_${doc.id}';
      if (existingIds.contains(noticeId) || existingIds.contains(doc.id)) {
        alertsSkipped++;
        continue;
      }

      final severity = (data['severity'] ?? 'info').toString().toLowerCase();
      final priority = switch (severity) {
        'critical' => 'urgent',
        'warning' => 'important',
        _ => 'normal',
      };
      final target = (data['target'] ?? 'all_drivers').toString();
      final driverId = data['driverId']?.toString();
      final created = NoticeModel.fromMap({
        'createdAt': data['createdAt'],
        'date': data['createdAt'],
      }, noticeId).createdAt;
      final expires = data['expiresAt'] == null
          ? null
          : NoticeModel.fromMap(
              {'expiresAt': data['expiresAt']},
              noticeId,
            ).expiresAt;

      final notice = NoticeModel(
        id: noticeId,
        title: (data['title'] ?? '').toString(),
        message: (data['message'] ?? '').toString(),
        audience: 'drivers',
        priority: priority,
        isActive: data['isActive'] != false,
        createdBy: (data['createdBy'] ?? 'Admin').toString(),
        createdAt: created,
        expiresAt: expires,
        targetDriverId: target == 'specific_driver' &&
                driverId != null &&
                driverId.isNotEmpty
            ? driverId
            : null,
      );

      batch.set(
        db.collection('notices').doc(noticeId),
        notice.toMap(),
        SetOptions(merge: true),
      );
      alertsCopied++;
      ops++;
      if (ops >= 400) await flush();
    }
    await flush();
    await refreshNotices();
    return (
      noticesBackfilled: noticesBackfilled,
      alertsCopied: alertsCopied,
      alertsSkipped: alertsSkipped,
    );
  }

  List<NoticeModel> _parseDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return FirestoreParse.mapDocs(
      docs,
      (data, id) => NoticeModel.fromMap(data, id),
      label: 'notices',
    );
  }

  Stream<List<NoticeModel>> _withSeed(
    Stream<List<NoticeModel>> live,
    List<NoticeModel> seed,
  ) {
    if (seed.isEmpty) return live;
    return Stream<List<NoticeModel>>.multi((controller) {
      controller.add(List.unmodifiable(seed));
      final sub = live.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }
}
