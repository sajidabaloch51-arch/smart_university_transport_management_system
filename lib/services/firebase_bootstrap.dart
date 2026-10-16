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
      await db.collection('_meta').doc('health').get().timeout(
            const Duration(seconds: 3),
          );
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

  static Future<String?> probeRealtimeDatabase() async {
    if (!isFirebaseReady) return 'Firebase is not initialized.';
    try {
      final ref = FirebaseDatabase.instance.ref('.info/connected');
      final snap = await ref.get().timeout(const Duration(seconds: 3));
      final connected = snap.value == true;
      if (!connected) {
        return 'Realtime Database not connected. Enable RTDB in Firebase Console '
            'for project sutms-uog.';
      }
      return null;
    } catch (e) {
      debugPrint('RTDB probe failed: $e');
      return 'Realtime Database unavailable. Enable it in Firebase Console.';
    }
  }
}
