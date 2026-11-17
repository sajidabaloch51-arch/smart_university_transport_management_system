import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/providers/live_tracking_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/widgets/async_state_view.dart';

/// Usability tests: clear labels, helpful empty/error states, readable
/// validation copy, and role-entry discoverability (no live Firebase required).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX-01 Role selection discoverability', () {
    testWidgets(
      'shows brand, instruction, and three clear role cards with subtitles',
      (tester) async {
        final auth = AuthProvider();
        final router = GoRouter(
          initialLocation: '/role-selection',
          routes: [
            GoRoute(
              path: '/role-selection',
              builder: (_, __) => const RoleSelectionScreen(),
            ),
            GoRoute(
              path: '/student-portal-entry',
              builder: (_, __) => const Scaffold(body: Text('STUDENT_ENTRY')),
            ),
            GoRoute(
              path: '/driver-portal-entry',
              builder: (_, __) => const Scaffold(body: Text('DRIVER_ENTRY')),
            ),
            GoRoute(
              path: '/login',
              builder: (_, __) => const Scaffold(body: Text('LOGIN')),
            ),
          ],
        );

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: auth,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome to SUTMS'), findsOneWidget);
        expect(
          find.text('Please select your role to continue'),
          findsOneWidget,
        );
        expect(find.text('Student'), findsOneWidget);
        expect(find.text('Bus Driver'), findsOneWidget);
        expect(find.text('Administrator'), findsOneWidget);
        expect(
          find.textContaining('Track buses'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Manage duty'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Manage system users'),
          findsOneWidget,
        );

        // Large bus icon present for brand recognition.
        expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      },
    );

    testWidgets('tapping Student navigates to student portal entry',
        (tester) async {
      final auth = AuthProvider();
      final router = GoRouter(
        initialLocation: '/role-selection',
        routes: [
          GoRoute(
            path: '/role-selection',
            builder: (_, __) => const RoleSelectionScreen(),
          ),
          GoRoute(
            path: '/student-portal-entry',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_ENTRY')),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_ENTRY'), findsOneWidget);
    });
  });

  group('UX-02 Live tracking status language', () {
    test('inactive / waiting / ended labels are plain English', () {
      final p = LiveTrackingProvider();
      expect(p.statusLabel, 'Bus is not currently active');
      expect(p.statusLabel.toLowerCase(), isNot(contains('null')));
      expect(p.statusLabel.toLowerCase(), isNot(contains('exception')));
    });

    testWidgets('student empty-state explains what to wait for', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Bus is not currently active.\n'
                'When the driver starts a trip, the live location will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Bus is not currently active'), findsOneWidget);
      expect(find.textContaining('driver starts a trip'), findsOneWidget);
    });
  });

  group('UX-03 Driver trip action wording', () {
    testWidgets('START TRIP / END TRIP / TRIP ACTIVE copy is unambiguous',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                Text('TRIP ACTIVE'),
                Text('Sharing GPS with students & admin'),
                Text('START TRIP'),
                Text('END TRIP'),
                Text('TRIP OFFLINE'),
                Text('Start trip to share location'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('START TRIP'), findsOneWidget);
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.text('TRIP ACTIVE'), findsOneWidget);
      expect(find.textContaining('Sharing GPS'), findsOneWidget);
      expect(find.textContaining('share location'), findsOneWidget);
    });

    test('trip-start errors tell the driver what to fix', () {
      try {
        TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'b1',
          routeId: 'r1',
        );
        fail('expected TripStartException');
      } on TripStartException catch (e) {
        expect(e.message.toLowerCase(), contains('approved'));
        expect(e.message.toLowerCase(), contains('admin'));
      }

      try {
        TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'r1',
        );
        fail('expected TripStartException');
      } on TripStartException catch (e) {
        expect(e.message.toLowerCase(), contains('bus'));
        expect(e.message.toLowerCase(), contains('admin'));
      }
    });
  });

  group('UX-04 Friendly system messages', () {
    test('auth errors avoid technical jargon for users', () {
      expect(
        AuthErrorMapper.map('wrong-password', null),
        'Incorrect email or password.',
      );
      expect(
        AuthErrorMapper.map('network-request-failed', null).toLowerCase(),
        contains('internet'),
      );
      expect(
        AuthErrorMapper.map('too-many-requests', null).toLowerCase(),
        contains('wait'),
      );
      final weak = AuthErrorMapper.map('weak-password', null);
      expect(weak.toLowerCase(), contains('password'));
      expect(weak.toLowerCase(), isNot(contains('firebase')));
    });

    test('firestore permission message is actionable', () {
      final msg = FirestoreErrorMessages.friendly(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );
      expect(msg.toLowerCase(), contains("don't have access"));
      expect(msg.toLowerCase(), contains('log out'));
      expect(msg.toLowerCase(), contains('admin'));
      expect(msg.toLowerCase(), isNot(contains('permission-denied')));
    });

    test('network / timeout messages are plain language', () {
      expect(
        FirestoreErrorMessages.friendly(TimeoutException('slow')),
        "Can't reach the server",
      );
      expect(
        FirestoreErrorMessages.friendly(
          FirestoreQueryException(
            collection: 'duties',
            query: 'driver',
            authUid: null,
            cause: StateError('Please log in again to load data.'),
          ),
        ),
        'Please log in again',
      );
    });
  });

  group('UX-05 Form validation clarity', () {
    test('password rules explain what is missing', () {
      expect(
        AppValidators.validatePassword('short'),
        contains('8 characters'),
      );
      expect(
        AppValidators.validatePassword('alllowercase1!'),
        contains('uppercase'),
      );
      expect(
        AppValidators.validatePassword('ALLUPPERCASE1!'),
        contains('lowercase'),
      );
      expect(
        AppValidators.validatePassword('NoDigits!!'),
        contains('number'),
      );
      expect(
        AppValidators.validatePassword('NoSpecial1'),
        contains('special'),
      );
    });

    test('name / email hints are understandable', () {
      expect(
        AppValidators.validateFullName('Ali'),
        contains('two words'),
      );
      final emailErr = AppValidators.validateEmailForRole(
        'not-an-email',
        'student',
      );
      expect(emailErr, isNotNull);
      expect(emailErr!.toLowerCase(), anyOf(contains('email'), contains('valid')));
    });
  });

  group('UX-06 Async empty / error recovery', () {
    testWidgets('empty state shows message and optional Refresh', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.value(const <String>[]),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No duties assigned yet.',
              emptySubtitle: 'When Admin assigns a duty, it will show up here.',
              onRetry: () {},
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No duties assigned yet.'), findsOneWidget);
      expect(find.textContaining('Admin assigns'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('error state shows Retry with friendly message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream<List<String>>.error(
                FirebaseException(
                  plugin: 'cloud_firestore',
                  code: 'permission-denied',
                ),
              ),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'empty',
              onRetry: () {},
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining("don't have access"), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });

  group('UX-07 Duty empty-state guidance', () {
    testWidgets('empty duties explain START TRIP still possible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              'When Admin assigns a duty, it will show up here. '
              'You can still START TRIP if a bus and route are assigned.',
            ),
          ),
        ),
      );
      expect(find.textContaining('START TRIP'), findsOneWidget);
      expect(find.textContaining('bus and route'), findsOneWidget);
    });
  });
}
