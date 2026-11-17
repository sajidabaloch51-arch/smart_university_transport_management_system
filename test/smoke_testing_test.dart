import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/providers/live_tracking_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/maps_service.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Smoke tests: fast critical-path checks that the app still boots key
/// surfaces and core live-tracking contracts without deep edge-case coverage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SM-01 App entry / role selection smoke', () {
    testWidgets('role selection builds with three roles', (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(home: RoleSelectionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to SUTMS'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Bus Driver'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Student role navigates to portal entry', (tester) async {
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

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_ENTRY'), findsOneWidget);
    });
  });

  group('SM-02 Auth critical-path smoke', () {
    test('unauthenticated users cannot open dashboards', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/student-dashboard',
          appAuthenticated: false,
          hasFirebaseUser: false,
          role: null,
        ),
        '/role-selection',
      );
    });

    test('authenticated student can open live tracking', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        isNull,
      );
    });

    test('authenticated admin can open admin live tracking', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        isNull,
      );
    });

    test('role homes resolve', () {
      expect(AuthRouteGuard.homeForRole('admin'), '/admin-dashboard');
      expect(AuthRouteGuard.homeForRole('driver'), '/driver-dashboard');
      expect(AuthRouteGuard.homeForRole('student'), '/student-dashboard');
    });
  });

  group('SM-03 START TRIP critical gate smoke', () {
    test('happy path allows approved assigned driver', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        returnsNormally,
      );
    });

    test('blocked path still throws for unapproved driver', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        throwsA(isA<TripStartException>()),
      );
    });
  });

  group('SM-04 Live trip / GPS model smoke', () {
    test('ACTIVE trip + GPS parse for student/admin map UI', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'uid_1',
        'routeId': 'r1',
        'busNumber': 'UG-01',
        'routeName': 'Jetty',
        'driverName': 'Ali',
        'status': 'ACTIVE',
      }, 'trip_1');
      expect(trip.isActive, isTrue);

      final gps = GpsLocationModel.fromMap({
        'busId': 'b1',
        'driverId': 'uid_1',
        'latitude': 25.145,
        'longitude': 62.36,
        'isActive': true,
      }, 'trip_1');
      expect(gps.hasValidCoords, isTrue);

      final tracker = LiveTrackingProvider();
      expect(tracker.statusLabel, isNotEmpty);
      expect(tracker.statusLabel.toLowerCase(), isNot(contains('exception')));
    });
  });

  group('SM-05 Map surface smoke', () {
    testWidgets('OsmMapView builds on normal phone bounds', (tester) async {
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
                followBus: true,
                busLabel: 'UG-01',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(OsmMapView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('MapsService ETA smoke for nearby points', () {
      final eta = MapsService().getETAString(
        const LatLng(25.1450, 62.3600),
        const LatLng(25.1500, 62.3650),
      );
      expect(eta, isNotEmpty);
    });
  });

  group('SM-06 Async UI shell smoke', () {
    testWidgets('loading → data path works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<String>(
              stream: Stream.value('OK'),
              isEmpty: (v) => v.isEmpty,
              emptyMessage: 'Empty',
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('error path shows Retry', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<String>(
              stream: Stream.error(StateError('boom')),
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
    });
  });

  group('SM-07 Free OSM stack / demo credentials smoke', () {
    test('pubspec still uses free OSM stack', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('flutter_map:'), isTrue);
      expect(pubspec.contains('latlong2:'), isTrue);
      expect(pubspec.contains('google_maps_flutter'), isFalse);
    });

    test('demo credentials are valid shapes', () {
      expect(DemoCredentials.adminEmail.contains('@'), isTrue);
      expect(DemoCredentials.driverEmail.contains('@'), isTrue);
      expect(DemoCredentials.studentEmail.contains('@'), isTrue);
      expect(AppEmailValidator.validate(DemoCredentials.adminEmail), isNull);
      expect(AppEmailValidator.validate(DemoCredentials.driverEmail), isNull);
      expect(
        AppEmailValidator.validateStudent(DemoCredentials.studentEmail),
        isNull,
      );
      expect(DemoCredentials.adminPassword.length, greaterThanOrEqualTo(8));
    });

    test('Android location permission still declared', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('ACCESS_FINE_LOCATION'), isTrue);
      expect(manifest.contains('FOREGROUND_SERVICE_LOCATION'), isTrue);
    });
  });
}
