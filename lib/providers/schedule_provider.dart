import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/live_firestore.dart';
import '../utils/firestore_parse.dart';

class ScheduleProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  static const _key = 'schedules_all';
  List<ScheduleModel> _cached = const [];
  List<ScheduleModel> get cachedSchedules => _cached;

  Stream<List<ScheduleModel>> streamSchedules() {
    if (LiveFirestore.db == null) {
      return Stream.value(const <ScheduleModel>[]);
    }
    final live = LiveFirestore.mapSnapshots(
      _key,
      (db) => db.collection('schedules').limit(50),
      (snapshot) {
        _cached = FirestoreParse.mapDocs(
          snapshot.docs,
          (data, id) => ScheduleModel.fromMap(data, id),
          label: 'schedules',
        );
        return _cached;
      },
      collectionLabel: 'schedules',
    );
    // Paint instantly from in-memory cache when warm-up already filled it.
    final seed = _cached;
    if (seed.isEmpty) return live;
    return Stream<List<ScheduleModel>>.multi((controller) {
      controller.add(seed);
      final sub = live.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  void restartSchedulesStream() {
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
