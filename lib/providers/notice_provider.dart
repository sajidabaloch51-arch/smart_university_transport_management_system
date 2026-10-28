import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/live_firestore.dart';
import '../utils/firestore_parse.dart';

class NoticeProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NoticeModel> _cache = [];
  List<NoticeModel> get notices => List.unmodifiable(_cache);

  static const _key = 'notices_all';

  List<NoticeModel> get cachedNotices => List.unmodifiable(_cache);

  Stream<List<NoticeModel>> streamNotices() {
    if (LiveFirestore.db == null) {
      return Stream.value(const <NoticeModel>[]);
    }
    final live = LiveFirestore.mapSnapshots(
      _key,
      (db) =>
          db.collection('notices').orderBy('date', descending: true).limit(50),
      (snapshot) {
        _cache = FirestoreParse.mapDocs(
          snapshot.docs,
          (data, id) => NoticeModel.fromMap(data, id),
          label: 'notices',
        );
        return _cache;
      },
      collectionLabel: 'notices',
    );
    final seed = _cache;
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

  void restartNoticesStream() {
    LiveFirestore.restart(_key);
  }

  Future<void> refreshNotices() => LiveFirestore.forceRefresh(_key);

  Stream<List<NoticeModel>> streamNoticesForRole(String role) {
    return streamNotices().map(
      (list) => list.where((n) => n.isVisibleTo(role)).toList(),
    );
  }

  List<NoticeModel> noticesForRole(String role) {
    return _cache.where((n) => n.isVisibleTo(role)).toList();
  }

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

  Future<void> deleteNotice(String id) async {
    final db = LiveFirestore.db;
    if (db == null) return;
    await db.collection('notices').doc(id).delete();
  }
}
