import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/live_firestore.dart';

class NoticeProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NoticeModel> _cache = [];
  List<NoticeModel> get notices => List.unmodifiable(_cache);

  Stream<List<NoticeModel>>? _noticesStream;
  static const _key = 'notices_all';

  List<NoticeModel> get cachedNotices => List.unmodifiable(_cache);

  Stream<List<NoticeModel>> streamNotices() {
    if (_noticesStream != null) return _noticesStream!;
    if (LiveFirestore.db == null) {
      return Stream.value(const <NoticeModel>[]);
    }

    _noticesStream = LiveFirestore.snapshots(
      _key,
      (db) =>
          db.collection('notices').orderBy('date', descending: true).limit(50),
      collectionLabel: 'notices',
    ).map((snapshot) {
      _cache = snapshot.docs
          .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
          .toList();
      return _cache;
    });
    return _noticesStream!;
  }

  void restartNoticesStream() {
    _noticesStream = null;
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
