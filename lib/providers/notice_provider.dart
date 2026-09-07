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

  final List<NoticeModel> _mockNotices = [
    NoticeModel(
      id: 'n1',
      title: 'Exam Schedule Transport',
      description: 'Extra buses will run during the final exams starting next Monday.',
      date: DateTime.now(),
      postedBy: 'Admin',
      type: NoticeType.general,
    ),
    NoticeModel(
      id: 'n2',
      title: 'Route A Delay',
      description: 'Route A bus is delayed by 15 minutes due to construction.',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      postedBy: 'System',
      type: NoticeType.delay,
    ),
  ];

  Stream<List<NoticeModel>> streamNotices() {
    try {
      final db = _db;
      if (db == null) return Stream.value(_mockNotices);

      return db.collection('notices')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      debugPrint("Error in streamNotices: $e");
      return Stream.value(_mockNotices);
    }
  }

  Future<void> addNotice(NoticeModel notice) async {
    final db = _db;
    if (db == null) {
      final index = _mockNotices.indexWhere((n) => n.id == notice.id);
      if (index != -1) {
        _mockNotices[index] = notice;
      } else {
        _mockNotices.insert(0, notice);
      }
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    await db.collection('notices').doc(notice.id).set(notice.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteNotice(String id) async {
    final db = _db;
    if (db == null) {
      _mockNotices.removeWhere((n) => n.id == id);
      notifyListeners();
      return;
    }
    await db.collection('notices').doc(id).delete();
  }
}
