import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Maps Firebase / network errors to short, user-facing messages.
class FirestoreErrorMessages {
  FirestoreErrorMessages._();

  /// Logs the real error (type, Firebase code/message, stack) then returns
  /// a user-facing string. Network wording is reserved for real network cases.
  static String friendly(Object error, [StackTrace? stack]) {
    _log(error, stack);

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "You don't have access to this data";
        case 'failed-precondition':
          debugPrint(
            '🔥 missing index / precondition: ${error.message}',
          );
          return 'A database index is missing (admin setup needed)';
        case 'unavailable':
        case 'network-request-failed':
          return "Can't reach the server. Check your connection";
        case 'deadline-exceeded':
          return 'This is taking longer than usual';
        case 'unauthenticated':
          return 'Please log in again';
        default:
          return error.message?.isNotEmpty == true
              ? error.message!
              : 'Something went wrong (${error.code})';
      }
    }

    if (error is TimeoutException) {
      return 'This is taking longer than usual';
    }
    if (error is SocketException) {
      return "Can't reach the server. Check your connection";
    }
    if (error is FormatException || error is TypeError) {
      return 'Some schedule data is invalid';
    }

    final s = error.toString().toLowerCase();
    if (s.contains('socketexception') ||
        s.contains('network-request-failed') ||
        s.contains('failed host lookup') ||
        s.contains('connection refused') ||
        s.contains('connection reset')) {
      return "Can't reach the server. Check your connection";
    }
    if (s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('deadline')) {
      return 'This is taking longer than usual';
    }
    if (s.contains('permission') || s.contains('permission-denied')) {
      return "You don't have access to this data";
    }
    if (s.contains('failed-precondition') || s.contains('requires an index')) {
      return 'A database index is missing (admin setup needed)';
    }
    if (s.contains('type') ||
        s.contains('cast') ||
        s.contains('format') ||
        s.contains('invalid')) {
      return 'Some data is invalid';
    }

    return 'Something went wrong. Tap Retry to try again.';
  }

  /// Same as [friendly], but if the device is offline forces the connection
  /// message (uses connectivity_plus).
  static Future<String> friendlyAsync(Object error, [StackTrace? stack]) async {
    try {
      final results = await Connectivity().checkConnectivity();
      final offline = results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none);
      if (offline) {
        _log(error, stack);
        return "Can't reach the server. Check your connection";
      }
    } catch (_) {
      // Connectivity plugin unavailable — fall through.
    }
    return friendly(error, stack);
  }

  /// Compact technical text for debug builds only.
  static String debugDetails(Object error) {
    if (error is FirebaseException) {
      return '${error.runtimeType} code=${error.code} message=${error.message}';
    }
    return '${error.runtimeType}: $error';
  }

  static void _log(Object error, StackTrace? stack) {
    if (error is FirebaseException) {
      debugPrint(
        '🔥 FirestoreError type=FirebaseException code=${error.code} '
        'message=${error.message}',
      );
    } else {
      debugPrint('🔥 FirestoreError type=${error.runtimeType} error=$error');
    }
    if (stack != null) {
      debugPrint('🔥 stack:\n$stack');
    }
  }
}
