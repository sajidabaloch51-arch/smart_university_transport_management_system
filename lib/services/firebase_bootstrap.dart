import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Reports whether Firebase / Firestore / RTDB are reachable for this app.
class FirebaseBootstrap {
  static bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  static FirebaseFirestore? get firestore {
    try {
      if (!isFirebaseReady) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Quick connectivity probe. Returns null when OK, otherwise an error message.
  static Future<String?> probeFirestore() async {
    final db = firestore;
    if (db == null) return 'Firebase is not initialized.';

    try {
      // Lightweight read against a reserved meta doc (may not exist — that's OK).
      // Web long-polling first connect can exceed 2s on cold start.
      await db
          .collection('_meta')
          .doc('health')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 12));
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found' ||
          (e.message?.contains('does not exist') ?? false)) {
        return 'Firestore database is not created for project sutms-uog. '
            'Open Firebase Console → Firestore → Create database.';
      }
      // Permission-denied still proves the DB exists.
      if (e.code == 'permission-denied') return null;
      return 'Firestore error: ${e.code} ${e.message}';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('does not exist for project')) {
        return 'Firestore database is not created for project sutms-uog. '
            'Open Firebase Console → Firestore → Create database.';
      }
      debugPrint('Firestore probe failed: $e');
      return 'Cannot reach Firestore. Check internet / Firebase setup.';
    }
  }

  /// Live bus GPS now uses Firestore trips/gps_locations — RTDB is optional.
  static Future<String?> probeRealtimeDatabase() async {
    if (!isFirebaseReady) return null;
    try {
      final ref = FirebaseDatabase.instance.ref('.info/connected');
      final snap = await ref.get().timeout(const Duration(seconds: 2));
      if (snap.value != true) {
        debugPrint('RTDB optional probe: not connected (OK for OSM/Firestore GPS)');
      }
    } catch (e) {
      debugPrint('RTDB optional probe skipped: $e');
    }
    return null;
  }
}
