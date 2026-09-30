import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {}
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<NoticeModel> _mockNotices = [];

  List<NoticeModel> get notices => List.unmodifiable(_mockNotices);

  Stream<List<NoticeModel>> streamNotices() {
    return Stream.value(List<NoticeModel>.from(_mockNotices));
  }

  Stream<List<NoticeModel>> streamNoticesForRole(String role) {
    final filtered = _mockNotices.where((n) => n.isVisibleTo(role)).toList();
    return Stream.value(filtered);
  }

  List<NoticeModel> noticesForRole(String role) {
    return _mockNotices.where((n) => n.isVisibleTo(role)).toList();
  }

  Future<void> addNotice(NoticeModel notice) async {
    final index = _mockNotices.indexWhere((n) => n.id == notice.id);
    if (index != -1) {
      _mockNotices[index] = notice;
    } else {
      _mockNotices.insert(0, notice);
    }
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('notices').doc(notice.id).set(notice.toMap()).then(
      (_) {},
      onError: (e) => debugPrint('Error saving notice: $e'),
    );
  }

  Future<void> deleteNotice(String id) async {
    _mockNotices.removeWhere((n) => n.id == id);
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('notices').doc(id).delete().then(
      (_) {},
      onError: (e) => debugPrint('Error deleting notice: $e'),
    );
  }
}
