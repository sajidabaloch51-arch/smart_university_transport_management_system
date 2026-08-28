import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<ScheduleModel>> streamSchedules() {
    return _db.collection('schedules')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('schedules').doc(schedule.id).set(schedule.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    await _db.collection('schedules').doc(id).delete();
  }
}
