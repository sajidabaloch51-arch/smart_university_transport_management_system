import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<NoticeModel> _cache = [];
  List<NoticeModel> get notices => List.unmodifiable(_cache);

  /// Live stream from Firestore `notices`.
  Stream<List<NoticeModel>> streamNotices() {
    final db = _db;
    if (db == null) return Stream.value(const <NoticeModel>[]);

    return db
        .collection('notices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      _cache = snapshot.docs
          .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
          .toList();
      return _cache;
    }).handleError((e) {
      debugPrint('streamNotices error: $e');
    });
  }

  Stream<List<NoticeModel>> streamNoticesForRole(String role) {
    return streamNotices().map(
      (list) => list.where((n) => n.isVisibleTo(role)).toList(),
    );
  }

  List<NoticeModel> noticesForRole(String role) {
    return _cache.where((n) => n.isVisibleTo(role)).toList();
  }

  Future<void> addNotice(NoticeModel notice) async {
    final db = _db;
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
    final db = _db;
    if (db == null) return;
    await db.collection('notices').doc(id).delete();
  }
}
