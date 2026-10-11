import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Live stream from Firestore `schedules`.
  Stream<List<ScheduleModel>> streamSchedules() {
    final db = _db;
    if (db == null) return Stream.value(const <ScheduleModel>[]);

    return db.collection('schedules').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((e) {
      debugPrint('streamSchedules error: $e');
    });
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    final db = _db;
    if (db == null) {
      throw Exception(
        'Firestore not available. Create the database in Firebase Console first.',
      );
    }
    _isLoading = true;
    notifyListeners();
    try {
      await db.collection('schedules').doc(schedule.id).set(schedule.toMap());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    final db = _db;
    if (db == null) return;
    await db.collection('schedules').doc(id).delete();
  }
}
