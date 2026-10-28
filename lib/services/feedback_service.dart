import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/feedback_categories.dart';
import '../models/feedback_model.dart';
import 'live_firestore.dart';

class FeedbackService {
  static const _allKey = 'feedback_all';
  static const _newKey = 'feedback_new_count';

  FirebaseFirestore? get _db => LiveFirestore.db;

  CollectionReference<Map<String, dynamic>>? get _col {
    final db = _db;
    if (db == null) return null;
    return db.collection('feedback');
  }

  void _log(String where, Object error) {
    LiveFirestore.log(where, collection: 'feedback', error: error);
  }

  /// Live stream of all feedback, newest first.
  Stream<List<FeedbackModel>> streamAllFeedback() {
    if (_col == null) {
      return Stream.error(StateError('Firestore not available for feedback'));
    }
    return LiveFirestore.mapSnapshots(
      _allKey,
      (db) => db.collection('feedback').orderBy('createdAt', descending: true),
      (snap) => snap.docs
          .map((d) => FeedbackModel.fromMap(d.data(), d.id))
          .toList(),
      collectionLabel: 'feedback',
    );
  }

  Stream<int> streamNewCount() {
    if (_col == null) return Stream.value(0);
    return LiveFirestore.mapSnapshots(
      _newKey,
      (db) => db
          .collection('feedback')
          .where('status', isEqualTo: FeedbackStatuses.newStatus),
      (snap) => snap.docs.length,
      collectionLabel: 'feedback(status=new)',
    );
  }

  void restartStreams() {
    LiveFirestore.restart(_allKey);
    LiveFirestore.restart(_newKey);
  }

  Future<String> submitFeedback({
    required String category,
    required String message,
    required String studentUid,
    String? studentName,
    String? rollNo,
    String? department,
  }) async {
    final col = _col;
    if (col == null) {
      throw StateError(
        'Firestore is not available. Check your connection and try again.',
      );
    }

    final trimmed = message.trim();
    if (category.trim().isEmpty) {
      throw ArgumentError('Category is required');
    }
    if (trimmed.length < 10 || trimmed.length > 1000) {
      throw ArgumentError('Message must be 10–1000 characters');
    }
    if (studentUid.isEmpty) {
      throw StateError('You must be signed in to send feedback.');
    }

    final doc = col.doc();
    final model = FeedbackModel(
      id: doc.id,
      category: category.trim(),
      message: trimmed,
      studentUid: studentUid,
      status: FeedbackStatuses.newStatus,
      createdAt: DateTime.now().toUtc(),
      studentName: studentName,
      rollNo: rollNo,
      department: department,
    );

    try {
      await doc.set(model.toCreateMap());
      return doc.id;
    } catch (e) {
      _log('FeedbackService.submitFeedback', e);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status, {String? adminNote}) async {
    final col = _col;
    if (col == null) {
      throw StateError('Firestore not available');
    }
    try {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (adminNote != null) data['adminNote'] = adminNote;
      await col.doc(id).update(data);
    } catch (e) {
      _log('FeedbackService.updateStatus', e);
      rethrow;
    }
  }

  Future<void> deleteFeedback(String id) async {
    final col = _col;
    if (col == null) {
      throw StateError('Firestore not available');
    }
    try {
      await col.doc(id).delete();
    } catch (e) {
      _log('FeedbackService.deleteFeedback', e);
      rethrow;
    }
  }

  /// One-time admin migration: normalize legacy docs into the shared schema.
  /// Also copies from alternate collection names if present.
  Future<int> migrateLegacyFeedback() async {
    final db = _db;
    if (db == null) throw StateError('Firestore not available');

    var migrated = 0;
    final target = db.collection('feedback');

    Future<void> normalizeCollection(String name) async {
      final snap = await db.collection(name).get();
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final model = FeedbackModel.fromMap(data, doc.id);

        final needsWrite = name != 'feedback' ||
            data['message'] == null ||
            data['category'] == null ||
            data['status'] == null ||
            data['studentUid'] == null ||
            data['createdAt'] == null;

        if (!needsWrite) continue;

        final payload = <String, dynamic>{
          'id': doc.id,
          'category': FeedbackCategories.all.contains(model.category)
              ? model.category
              : FeedbackCategories.other,
          'message': model.message.isEmpty ? '(legacy empty message)' : model.message,
          'studentUid': model.studentUid,
          'status': FeedbackStatuses.all.contains(model.status)
              ? model.status
              : FeedbackStatuses.newStatus,
          'createdAt': data['createdAt'] ??
              data['timestamp'] ??
              data['date'] ??
              FieldValue.serverTimestamp(),
          if (model.studentName != null) 'studentName': model.studentName,
          if (model.rollNo != null) 'rollNo': model.rollNo,
          if (model.department != null) 'department': model.department,
          if (model.adminNote != null) 'adminNote': model.adminNote,
          'migratedAt': FieldValue.serverTimestamp(),
        };

        if (name == 'feedback') {
          await target.doc(doc.id).set(payload, SetOptions(merge: true));
        } else {
          await target.doc(doc.id).set(payload, SetOptions(merge: true));
        }
        migrated++;
      }
    }

    try {
      await normalizeCollection('feedback');
      // Older possible collection names (no-op if empty / missing).
      for (final alt in ['feedbacks', 'studentFeedback', 'student_feedback']) {
        try {
          await normalizeCollection(alt);
        } catch (e) {
          debugPrint('migrateLegacyFeedback skip $alt: $e');
        }
      }
      return migrated;
    } catch (e) {
      _log('FeedbackService.migrateLegacyFeedback', e);
      rethrow;
    }
  }
}
