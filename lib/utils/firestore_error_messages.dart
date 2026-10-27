import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Maps Firebase / network errors to short, user-facing messages.
class FirestoreErrorMessages {
  FirestoreErrorMessages._();

  static String friendly(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "You don't have access to this data";
        case 'failed-precondition':
          debugPrint(
            '🔥 missing index / precondition: ${error.message}',
          );
          return 'Setup needed (missing index). Ask Admin to deploy Firestore indexes.';
        case 'unavailable':
        case 'deadline-exceeded':
        case 'network-request-failed':
          return "Can't reach the server. Check your connection";
        case 'unauthenticated':
          return 'Please log in again';
        default:
          return error.message?.isNotEmpty == true
              ? error.message!
              : 'Something went wrong (${error.code})';
      }
    }
    final s = error.toString().toLowerCase();
    if (s.contains('socket') ||
        s.contains('network') ||
        s.contains('offline') ||
        s.contains('timed out') ||
        s.contains('timeout')) {
      return "Can't reach the server. Check your connection";
    }
    return error.toString();
  }
}
