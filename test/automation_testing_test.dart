import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Automation tests: scripted multi-step UI / flow sequences that mimic
/// user actions (tap → navigate → assert) without live Firebase/device GPS.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter roleRouter() {
    return GoRouter(
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
          builder: (_, __) => const Scaffold(body: Text('ADMIN_LOGIN')),
        ),
      ],
    );
  }

  Future<void> pumpRoleApp(WidgetTester tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp.router(routerConfig: roleRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AT-01 Automated role-entry flows', () {
    testWidgets('script: open app → tap Student → portal entry', (tester) async {
      await pumpRoleApp(tester);
      expect(find.text('Welcome to SUTMS'), findsOneWidget);

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_ENTRY'), findsOneWidget);
    });

    testWidgets('script: open app → tap Bus Driver → portal entry',
        (tester) async {
      await pumpRoleApp(tester);
      await tester.tap(find.text('Bus Driver'));
      await tester.pumpAndSettle();
      expect(find.text('DRIVER_ENTRY'), findsOneWidget);
    });

    testWidgets('script: open app → tap Administrator → login', (tester) async {
      await pumpRoleApp(tester);
      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();
      expect(find.text('ADMIN_LOGIN'), findsOneWidget);
    });
  });

  group('AT-02 Automated RBAC redirect matrix', () {
    test('scripted role × path decisions stay correct', () {
      const cases = <(String role, String path, String? expected)>[
        ('student', '/live-tracking', null),
        ('student', '/admin-live-tracking', '/student-dashboard'),
        ('student', '/driver-dashboard', '/student-dashboard'),
        ('driver', '/live-tracking', '/driver-dashboard'),
        ('driver', '/admin-live-tracking', '/driver-dashboard'),
        ('admin', '/admin-live-tracking', null),
        ('admin', '/live-tracking', '/admin-dashboard'),
        ('admin', '/driver-dashboard', '/admin-dashboard'),
      ];

      for (final c in cases) {
        final actual = AuthRouteGuard.redirect(
          location: c.$2,
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: c.$1,
        );
        expect(
          actual,
          c.$3,
          reason: '${c.$1} → ${c.$2} expected ${c.$3}, got $actual',
        );
      }
    });

    testWidgets('script: student router blocks admin live path', (tester) async {
      final router = GoRouter(
        initialLocation: '/live-tracking',
        redirect: (context, state) {
          return AuthRouteGuard.redirect(
            location: state.matchedLocation,
            appAuthenticated: true,
            hasFirebaseUser: true,
            role: 'student',
          );
        },
        routes: [
          GoRoute(
            path: '/live-tracking',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_LIVE')),
          ),
          GoRoute(
            path: '/admin-live-tracking',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_LIVE')),
          ),
          GoRoute(
            path: '/student-dashboard',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_HOME')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_LIVE'), findsOneWidget);

      router.go('/admin-live-tracking');
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_HOME'), findsOneWidget);
      expect(find.text('ADMIN_LIVE'), findsNothing);
    });
  });

  group('AT-03 Automated START TRIP gate sequence', () {
    test('script: pending → denied; assign bus/route → approved → allow', () {
      // Step 1: pending verification
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: null,
          routeId: null,
        ),
        throwsA(isA<TripStartException>()),
      );

      // Step 2: approved but unassigned
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'Not Assigned',
        ),
        throwsA(isA<TripStartException>()),
      );

      // Step 3: bus only
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'Not Assigned',
        ),
        throwsA(isA<TripStartException>()),
      );

      // Step 4: fully assigned
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        returnsNormally,
      );
    });

    testWidgets('script: duty controls show START then END after toggle',
        (tester) async {
      var onDuty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Text(onDuty ? 'TRIP ACTIVE' : 'TRIP OFFLINE'),
                    ElevatedButton(
                      onPressed: () => setState(() => onDuty = !onDuty),
                      child: Text(onDuty ? 'END TRIP' : 'START TRIP'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('START TRIP'), findsOneWidget);
      expect(find.text('TRIP OFFLINE'), findsOneWidget);

      await tester.tap(find.text('START TRIP'));
      await tester.pumpAndSettle();
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.text('TRIP ACTIVE'), findsOneWidget);

      await tester.tap(find.text('END TRIP'));
      await tester.pumpAndSettle();
      expect(find.text('START TRIP'), findsOneWidget);
      expect(find.text('TRIP OFFLINE'), findsOneWidget);
    });
  });

  group('AT-04 Automated live map + trip data pipeline', () {
    test('script: ACTIVE trip + GPS → finite LatLng for map', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'uid_1',
        'routeId': 'r1',
        'busNumber': 'UG-01',
        'status': 'ACTIVE',
      }, 't1');
      expect(trip.isActive, isTrue);

      final gps = GpsLocationModel.fromMap({
        'busId': 'b1',
        'driverId': 'uid_1',
        'latitude': 25.145,
        'longitude': 62.36,
        'isActive': true,
      }, 't1');
      expect(gps.hasValidCoords, isTrue);

      final point = LatLng(gps.latitude, gps.longitude);
      expect(point.latitude.isFinite && point.longitude.isFinite, isTrue);
    });

    testWidgets('script: pump OsmMapView with bus → no layout overflow',
        (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('ClientException') || msg.contains('status 400')) {
          return;
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 280,
              child: OsmMapView(
                busLocation: LatLng(25.1450, 62.3600),
                busLabel: 'UG-01',
                followBus: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byType(OsmMapView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AT-05 Automated AsyncStateView recovery', () {
    testWidgets('script: error → tap Retry → data appears', (tester) async {
      var attempt = 0;
      Stream<String> factory() {
        attempt++;
        if (attempt == 1) {
          return Stream.error(StateError('temporary'));
        }
        return Stream.value('LOADED');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<String>(
              stream: factory(),
              streamFactory: factory,
              isEmpty: (v) => v.isEmpty,
              emptyMessage: 'Empty',
              onRetry: () {},
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('LOADED'), findsOneWidget);
    });

    testWidgets('script: empty list → Refresh callback fires', (tester) async {
      var refreshed = 0;
      Stream<List<String>> factory() => Stream.value(const <String>[]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: factory(),
              streamFactory: factory,
              isEmpty: (items) => items.isEmpty,
              emptyMessage: 'No duties assigned yet.',
              emptySubtitle:
                  'You can still START TRIP if a bus and route are assigned.',
              onRetry: () => refreshed++,
              builder: (context, items) => Text(items.join(',')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No duties assigned yet.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(refreshed, 1);
      expect(find.text('No duties assigned yet.'), findsOneWidget);
    });
  });

  group('AT-06 Automated form validation sequences', () {
    test('script: weak → stronger passwords until valid', () {
      expect(AppValidators.validatePassword('123'), isNotNull);
      expect(AppValidators.validatePassword('abcdef'), isNotNull);
      expect(AppValidators.validatePassword('Password1!'), isNull);
    });

    test('script: email normalize then validate for roles', () {
      final normalized = AppEmailValidator.normalize('  Ali@UOG.EDU.PK ');
      expect(normalized, 'ali@uog.edu.pk');
      expect(AppEmailValidator.validate(normalized), isNull);
      expect(
        AppEmailValidator.validateStudent('ali@student.ug.edu.pk'),
        isNull,
      );
      expect(
        AppEmailValidator.validate('ali@student.ug.edu.pk'),
        isNotNull,
      );
    });
  });
}
