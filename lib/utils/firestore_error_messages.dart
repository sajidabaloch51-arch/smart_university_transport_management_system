import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firestore_query_exception.dart';

/// Maps Firebase / network errors to short, user-facing messages.
class FirestoreErrorMessages {
  FirestoreErrorMessages._();

  /// Logs the real error (type, Firebase code/message, stack) then returns
  /// a user-facing string. Network wording is reserved for real network cases.
  static String friendly(Object error, [StackTrace? stack]) {
    _log(error, stack);

    final root = error is FirestoreQueryException ? error.cause : error;

    if (error is FirestoreQueryException && error.isUnauthenticated) {
      return 'Please log in again';
    }

    if (root is FirebaseException) {
      switch (root.code) {
        case 'permission-denied':
          return "You don't have access to this data. "
              'Log out and sign in again with the correct role, '
              'or ask Admin if your account is approved.';
        case 'failed-precondition':
          debugPrint('🔥 missing index / precondition: ${root.message}');
          return 'Database index missing';
        case 'unavailable':
        case 'network-request-failed':
          return "Can't reach the server";
        case 'deadline-exceeded':
          return "Can't reach the server";
        case 'unauthenticated':
          return 'Please log in again';
        default:
          return root.message?.isNotEmpty == true
              ? root.message!
              : 'Something went wrong (${root.code})';
      }
    }

    if (root is TimeoutException) {
      return "Can't reach the server";
    }
    if (root is SocketException) {
      return "Can't reach the server";
    }
    if (root is FormatException || root is TypeError) {
      final id = _docIdFromMessage(root.toString());
      return id != null
          ? 'Some data is invalid (document $id)'
          : 'Some data is invalid';
    }

    final s = root.toString().toLowerCase();
    if (s.contains('please log in') ||
        s.contains('unauthenticated') ||
        s.contains('auth not ready') ||
        s.contains('authuid=null')) {
      return 'Please log in again';
    }
    if (s.contains('socketexception') ||
        s.contains('network-request-failed') ||
        s.contains('failed host lookup') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('unavailable')) {
      return "Can't reach the server";
    }
    if (s.contains('timed out') ||
        s.contains('timeout') ||
        s.contains('deadline')) {
      return "Can't reach the server";
    }
    if (s.contains('permission-denied') || s.contains('permission')) {
      return "You don't have access to this data";
    }
    if (s.contains('failed-precondition') || s.contains('requires an index')) {
      return 'Database index missing';
    }
    if (s.contains('type') ||
        s.contains('cast') ||
        s.contains('format') ||
        s.contains('invalid') ||
        s.contains('skipping bad')) {
      final id = _docIdFromMessage(root.toString());
      return id != null
          ? 'Some data is invalid (document $id)'
          : 'Some data is invalid';
    }

    return 'Something went wrong. Tap Retry to try again.';
  }

  static String? _docIdFromMessage(String raw) {
    final m = RegExp(r'doc(?:ument)?[=\s]+([A-Za-z0-9_-]+)').firstMatch(raw);
    return m?.group(1);
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
        return "Can't reach the server";
      }
    } catch (_) {
      // Connectivity plugin unavailable — fall through.
    }
    return friendly(error, stack);
  }

  static String _safeAuthUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'null';
    } catch (_) {
      return 'null';
    }
  }

  /// Technical details for the Details panel (always available).
  static String debugDetails(Object error, [StackTrace? stack]) {
    final buf = StringBuffer();
    final uid = _safeAuthUid();

    if (error is FirestoreQueryException) {
      buf.writeln('type=${error.cause.runtimeType}');
      buf.writeln('collection=${error.collection}');
      buf.writeln('query=${error.query}');
      buf.writeln('authUid=${error.authUid ?? uid}');
      final fe = error.firebaseException;
      if (fe != null) {
        buf.writeln('firebaseCode=${fe.code}');
        buf.writeln('firebaseMessage=${fe.message}');
      } else {
        buf.writeln('cause=${error.cause}');
      }
      if (error.causeStack != null) {
        buf.writeln('stack:');
        buf.writeln(error.causeStack);
      } else if (stack != null) {
        buf.writeln('stack:');
        buf.writeln(stack);
      }
      return buf.toString().trimRight();
    }

    buf.writeln('type=${error.runtimeType}');
    buf.writeln('authUid=$uid');
    if (error is FirebaseException) {
      buf.writeln('firebaseCode=${error.code}');
      buf.writeln('firebaseMessage=${error.message}');
    } else {
      buf.writeln('message=$error');
    }
    if (stack != null) {
      buf.writeln('stack:');
      buf.writeln(stack);
    }
    return buf.toString().trimRight();
  }

  static void _log(Object error, StackTrace? stack) {
    final details = debugDetails(error, stack);
    debugPrint('🔥 FirestoreError\n$details');
    if (stack != null && error is! FirestoreQueryException) {
      debugPrint('🔥 stack:\n$stack');
    }
  }
}

/// Expandable Details block with selectable text + Copy.
class FirestoreErrorDetailsPanel extends StatefulWidget {
  final String details;

  const FirestoreErrorDetailsPanel({super.key, required this.details});

  @override
  State<FirestoreErrorDetailsPanel> createState() =>
      _FirestoreErrorDetailsPanelState();
}

class _FirestoreErrorDetailsPanelState extends State<FirestoreErrorDetailsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Hide details' : 'Details'),
        ),
        if (_expanded) ...[
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                widget.details,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.details));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Details copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ],
    );
  }
}
