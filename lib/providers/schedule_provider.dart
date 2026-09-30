import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {}
    return null;
  }
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<ScheduleModel> _mockSchedules = [];

  Stream<List<ScheduleModel>> streamSchedules() {
    return Stream.value(List<ScheduleModel>.from(_mockSchedules));
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    final index = _mockSchedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _mockSchedules[index] = schedule;
    } else {
      _mockSchedules.add(schedule);
    }
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('schedules').doc(schedule.id).set(schedule.toMap()).then(
      (_) {},
      onError: (e) => debugPrint('Error saving schedule: $e'),
    );
  }

  Future<void> deleteSchedule(String id) async {
    _mockSchedules.removeWhere((s) => s.id == id);
    notifyListeners();

    final db = _db;
    if (db == null) return;
    db.collection('schedules').doc(id).delete().then(
      (_) {},
      onError: (e) => debugPrint('Error deleting schedule: $e'),
    );
  }
}
