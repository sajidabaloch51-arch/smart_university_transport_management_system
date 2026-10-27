import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/live_firestore.dart';

class ScheduleProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<ScheduleModel>>? _schedulesStream;
  static const _key = 'schedules_all';
  List<ScheduleModel> _cached = const [];
  List<ScheduleModel> get cachedSchedules => _cached;

  Stream<List<ScheduleModel>> streamSchedules() {
    if (_schedulesStream != null) return _schedulesStream!;
    if (LiveFirestore.db == null) {
      return Stream.value(const <ScheduleModel>[]);
    }

    _schedulesStream = LiveFirestore.snapshots(
      _key,
      (db) => db.collection('schedules'),
      collectionLabel: 'schedules',
    ).map((snapshot) {
      _cached = snapshot.docs
          .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
          .toList();
      return _cached;
    });
    return _schedulesStream!;
  }

  void restartSchedulesStream() {
    _schedulesStream = null;
    LiveFirestore.restart(_key);
  }

  Future<void> refreshSchedules() => LiveFirestore.forceRefresh(_key);

  Future<void> addSchedule(ScheduleModel schedule) async {
    final db = LiveFirestore.db;
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
    final db = LiveFirestore.db;
    if (db == null) return;
    await db.collection('schedules').doc(id).delete();
  }
}
