import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint("Firestore access error: $e");
    }
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<ScheduleModel> _mockSchedules = [
    ScheduleModel(id: 's1', busNumber: 'UOG-001', routeName: 'Route A', departureTime: '08:00 AM', arrivalTime: '08:45 AM', days: ['Mon', 'Tue', 'Wed']),
  ];

  Stream<List<ScheduleModel>> streamSchedules() {
    final db = _db;
    if (db == null) return Stream.value(_mockSchedules);

    return db.collection('schedules')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    final db = _db;
    if (db == null) {
      _mockSchedules.add(schedule);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    await db.collection('schedules').doc(schedule.id).set(schedule.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    final db = _db;
    if (db == null) {
      _mockSchedules.removeWhere((s) => s.id == id);
      notifyListeners();
      return;
    }
    await db.collection('schedules').doc(id).delete();
  }
}
