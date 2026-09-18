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

  final List<ScheduleModel> _mockSchedules = [
    ScheduleModel(
      id: 's1',
      driverId: 'drv1',
      driverName: 'Nasir Ali',
      routeId: 'r1',
      routeName: 'Route A',
      date: DateTime.now(),
      departureTime: '08:00 AM',
      arrivalTime: '08:45 AM',
      shift: 'Morning',
      vehicleNo: 'UOG-001',
      status: 'Scheduled',
    ),
  ];

  Stream<List<ScheduleModel>> streamSchedules() {
    try {
      final db = _db;
      if (db == null) return Stream.value(_mockSchedules);

      return db.collection('schedules')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      debugPrint("Error in streamSchedules: $e");
      return Stream.value(_mockSchedules);
    }
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    final db = _db;
    if (db == null) {
      final index = _mockSchedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _mockSchedules[index] = schedule;
      } else {
        _mockSchedules.add(schedule);
      }
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
