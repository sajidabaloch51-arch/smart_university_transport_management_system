import 'package:firebase_auth/firebase_auth.dart';

/// Carries Firestore context so UI Details / logs show the real failure.
class FirestoreQueryException implements Exception {
  final String collection;
  final String query;
  final String? authUid;
  final Object cause;
  final StackTrace? causeStack;

  FirestoreQueryException({
    required this.collection,
    required this.query,
    required this.cause,
    this.authUid,
    this.causeStack,
  });

  factory FirestoreQueryException.wrap({
    required String collection,
    required String query,
    required Object cause,
    StackTrace? causeStack,
  }) {
    return FirestoreQueryException(
      collection: collection,
      query: query,
      cause: cause,
      causeStack: causeStack,
      authUid: () {
        try {
          return FirebaseAuth.instance.currentUser?.uid;
        } catch (_) {
          return null;
        }
      }(),
    );
  }

  bool get isUnauthenticated {
    if (cause is StateError) {
      final m = cause.toString().toLowerCase();
      return m.contains('log in') || m.contains('auth');
    }
    if (cause is FirebaseException) {
      return (cause as FirebaseException).code == 'unauthenticated';
    }
    return authUid == null || authUid!.isEmpty;
  }

  FirebaseException? get firebaseException =>
      cause is FirebaseException ? cause as FirebaseException : null;

  @override
  String toString() =>
      'FirestoreQueryException(collection=$collection, query=$query, '
      'authUid=${authUid ?? 'null'}, cause=$cause)';
}
