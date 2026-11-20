import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/widgets/async_state_view.dart';

/// Error Handling tests: auth / Firestore / trip / validation failures map to
/// honest user-facing messages and recoverable UI (Retry), without jargon.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool _noJargon(String msg) {
    final s = msg.toLowerCase();
    return !s.contains('exception') &&
        !s.contains('stack') &&
        !s.contains('nullpointer') &&
        !s.contains('firebaseexception');
  }

  group('EH-01 AuthErrorMapper', () {
    test('credential codes collapse to one safe message', () {
      for (final code in [
        'wrong-password',
        'invalid-credential',
        'invalid-login-credentials',
      ]) {
        final msg = AuthErrorMapper.map(code, 'secret server detail');
        expect(msg, 'Incorrect email or password.');
        expect(msg.toLowerCase(), isNot(contains('secret')));
        expect(_noJargon(msg), isTrue);
      }
    });

    test('network and rate-limit codes are actionable', () {
      final net = AuthErrorMapper.map('network-request-failed', null);
      expect(net.toLowerCase(), contains('internet'));
      expect(_noJargon(net), isTrue);

      final wait = AuthErrorMapper.map('too-many-requests', null);
      expect(wait.toLowerCase(), contains('wait'));
      expect(_noJargon(wait), isTrue);
    });

    test('configuration error explains Email/Password enablement', () {
      final msg = AuthErrorMapper.map('internal-error', 'CONFIGURATION_NOT_FOUND');
      expect(msg.toLowerCase(), contains('email/password'));
      expect(AuthErrorMapper.isConfigurationError(msg), isTrue);
    });

    test('classifier helpers for mismatch / missing user / email in use', () {
      expect(
        AuthErrorMapper.isCredentialMismatch(
          StateError('invalid-credential'),
        ),
        isTrue,
      );
      expect(
        AuthErrorMapper.isUserMissing(StateError('user-not-found')),
        isTrue,
      );
      expect(
        AuthErrorMapper.isEmailInUse(StateError('email-already-in-use')),
        isTrue,
      );
    });
  });

  group('EH-02 FirestoreErrorMessages', () {
    test('permission-denied is actionable and hides raw code', () {
      final msg = FirestoreErrorMessages.friendly(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );
      expect(msg.toLowerCase(), contains("don't have access"));
      expect(msg.toLowerCase(), contains('log out'));
      expect(msg.toLowerCase(), isNot(contains('permission-denied')));
      expect(_noJargon(msg), isTrue);
    });

    test('timeout / unavailable map to reachability copy', () {
      expect(
        FirestoreErrorMessages.friendly(TimeoutException('slow')),
        "Can't reach the server",
      );
      expect(
        FirestoreErrorMessages.friendly(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'down',
          ),
        ),
        "Can't reach the server",
      );
    });

    test('unauthenticated query exception asks to log in again', () {
      final msg = FirestoreErrorMessages.friendly(
        FirestoreQueryException(
          collection: 'duties',
          query: 'driver',
          authUid: null,
          cause: StateError('Please log in again to load data.'),
        ),
      );
      expect(msg, 'Please log in again');
      expect(_noJargon(msg), isTrue);
    });

    test('unknown errors still offer Retry guidance', () {
      final msg = FirestoreErrorMessages.friendly(StateError('weird blob'));
      expect(msg.toLowerCase(), contains('retry'));
      expect(_noJargon(msg), isTrue);
    });
  });

  group('EH-03 Trip start failures', () {
    test('unapproved / missing assignment throw clear TripStartException', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'b1',
          routeId: 'r1',
        ),
        throwsA(
          isA<TripStartException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('approved'),
          ),
        ),
      );

      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'r1',
        ),
        throwsA(
          isA<TripStartException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            allOf(contains('bus'), contains('admin')),
          ),
        ),
      );

      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'b1',
          routeId: '',
        ),
        throwsA(
          isA<TripStartException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('route'),
          ),
        ),
      );
    });
  });

  group('EH-04 Validation error copy', () {
    test('password and identity validators explain what to fix', () {
      expect(
        AppValidators.validatePassword('short'),
        contains('8 characters'),
      );
      expect(
        AppValidators.validatePhone('123'),
        contains('03'),
      );
      expect(
        AppValidators.validateFullName('Ali'),
        contains('two words'),
      );
      expect(
        AppValidators.validateConfirmPassword('a', 'b'),
        contains('match'),
      );
    });
  });

  group('EH-05 AsyncStateView recovery UI', () {
    testWidgets('error pane shows friendly message and Retry restores data',
        (tester) async {
      var retries = 0;
      StreamController<List<String>>? controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.error(
                FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'permission-denied',
                ),
              ),
              streamFactory: () {
                retries++;
                controller?.close();
                controller = StreamController<List<String>>();
                controller!.add(const ['recovered']);
                return controller!.stream;
              },
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'Empty',
              builder: (_, data) => Text(data.first),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("don't have access"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retries, 1);
      expect(find.text('recovered'), findsOneWidget);

      await controller?.close();
    });

    testWidgets('unauthenticated empty error asks to log in again',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.error(
                FirestoreQueryException(
                  collection: 'users',
                  query: 'list',
                  authUid: null,
                  cause: StateError('Please log in again to load data.'),
                ),
              ),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'Empty',
              builder: (_, data) => Text('data ${data.length}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Please log in again'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
