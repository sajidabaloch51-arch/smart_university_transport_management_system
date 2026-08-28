import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';

class NoticeProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<NoticeModel>> streamNotices() {
    return _db.collection('notices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addNotice(NoticeModel notice) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('notices').doc(notice.id).set(notice.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteNotice(String id) async {
    await _db.collection('notices').doc(id).delete();
  }
}
