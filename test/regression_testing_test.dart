import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/providers/live_tracking_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/maps_service.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Regression suite: re-checks previously fixed bugs and critical contracts
/// so they do not resurface (map overflow/NaN, RBAC, trip/GPS gates,
/// permission messaging, OSM stack, duty empty-state, auth hashing).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RT-01 OsmMapView regressions (NaN / overflow / tiny bounds)', () {
    testWidgets('tiny bounds show placeholder instead of TileLayer crash',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 16,
              height: 16,
              child: OsmMapView(followBus: false),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bus marker does not RenderFlex-overflow on phone map',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

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
      await tester.pump(const Duration(milliseconds: 100));

      final overflow = tester.takeException();
      expect(
        overflow,
        isNull,
        reason: 'bus marker Column must fit Marker bounds: $overflow',
      );
      expect(find.byType(OsmMapView), findsOneWidget);
    });

    testWidgets('invalid / NaN coords fall back without crashing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 240,
              child: OsmMapView(
                busLocation: LatLng(double.nan, double.infinity),
                routePoints: [
                  LatLng(double.nan, 0),
                  LatLng(25.14, 62.36),
                ],
                followBus: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OsmMapView), findsOneWidget);
      // Tile HTTP noise is OK; layout/NaN crash is not.
      final ex = tester.takeException();
      if (ex != null) {
        final msg = ex.toString();
        expect(
          msg.contains('NaN') || msg.contains('Infinity'),
          isFalse,
          reason: 'map must not throw NaN/Infinity: $ex',
        );
      }
    });
  });

  group('RT-02 Duty empty-state + START TRIP guidance', () {
    testWidgets('empty duties still explain START TRIP is possible',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.value(const <String>[]),
              isEmpty: (items) => items.isEmpty,
              emptyMessage: 'No duties assigned yet.',
              emptySubtitle:
                  'When Admin assigns a duty, it will show up here. '
                  'You can still START TRIP if a bus and route are assigned.',
              builder: (context, items) => Text(items.join(',')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No duties assigned yet.'), findsOneWidget);
      expect(find.textContaining('START TRIP'), findsOneWidget);
    });
  });

  group('RT-03 Auth RBAC regressions', () {
    test('anonymous users redirected from dashboards', () {
      for (final path in [
        '/admin-dashboard',
        '/driver-dashboard',
        '/student-dashboard',
        '/live-tracking',
        '/admin-live-tracking',
      ]) {
        expect(
          AuthRouteGuard.redirect(
            location: path,
            appAuthenticated: false,
            hasFirebaseUser: false,
            role: null,
          ),
          '/role-selection',
        );
      }
    });

    test('student cannot open admin or driver areas', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/driver-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
      );
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

    test('driver cannot open admin live tracking or student live tracking', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'driver',
        ),
        '/driver-dashboard',
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'driver',
        ),
        '/driver-dashboard',
      );
    });

    test('role homes stay stable', () {
      expect(AuthRouteGuard.homeForRole('admin'), '/admin-dashboard');
      expect(AuthRouteGuard.homeForRole('driver'), '/driver-dashboard');
      expect(AuthRouteGuard.homeForRole('student'), '/student-dashboard');
    });
  });

  group('RT-04 Trip START gate regressions', () {
    test('pending / suspended / missing assignment still blocked', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'b1',
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'suspended',
          busId: 'b1',
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'b1',
          routeId: '',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('approved driver with bus + route allowed', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'Approved',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        returnsNormally,
      );
    });
  });

  group('RT-05 Trip / GPS model contracts (auth uid shaped)', () {
    test('ACTIVE trip + GPS maps keep driverId and never leak password', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'auth_uid_driver',
        'routeId': 'r1',
        'busNumber': 'UG-01',
        'routeName': 'Jetty',
        'driverName': 'Ali',
        'status': 'ACTIVE',
      }, 'trip_1');
      expect(trip.isActive, isTrue);
      expect(trip.driverId, 'auth_uid_driver');
      expect(trip.toMap().containsKey('password'), isFalse);
      expect(trip.toMap().containsKey('role'), isFalse);

      final gps = GpsLocationModel.fromMap({
        'tripId': 'trip_1',
        'busId': 'b1',
        'driverId': 'auth_uid_driver',
        'latitude': 25.145,
        'longitude': 62.36,
        'isActive': true,
      }, 'trip_1');
      expect(gps.driverId, 'auth_uid_driver');
      expect(gps.hasValidCoords, isTrue);
      expect(gps.toMap()['driverId'], 'auth_uid_driver');
      expect(gps.toMap().containsKey('password'), isFalse);
    });

    test('zero placeholder coords are not treated as valid GPS', () {
      final gps = GpsLocationModel.fromMap({
        'busId': 'b1',
        'driverId': 'uid',
        'latitude': 0,
        'longitude': 0,
        'isActive': true,
      }, 't1');
      expect(gps.hasValidCoords, isFalse);
      expect(gps.isLive, isFalse);
    });
  });

  group('RT-06 Friendly permission / network messaging', () {
    test('permission-denied stays actionable (not raw Firebase jargon)', () {
      final msg = FirestoreErrorMessages.friendly(
        StateError('permission-denied'),
      );
      expect(msg.toLowerCase(), contains("don't have access"));
      expect(msg.toLowerCase(), isNot(contains('firebaseexception')));
      expect(msg.toLowerCase(), isNot(contains('stacktrace')));
    });

    test('auth wrong-password does not leak internals', () {
      final msg = AuthErrorMapper.map('wrong-password', null);
      expect(msg.toLowerCase(), contains('password'));
      expect(msg.toLowerCase(), isNot(contains('firebase')));
      expect(msg.toLowerCase(), isNot(contains('exception')));
    });
  });

  group('RT-07 Live tracking status labels', () {
    test('default / waiting / ended wording remains plain English', () {
      final p = LiveTrackingProvider();
      expect(p.statusLabel, 'Bus is not currently active');
      expect(p.statusLabel.toLowerCase(), isNot(contains('null')));
      expect(p.statusLabel.toLowerCase(), isNot(contains('exception')));
    });
  });

  group('RT-08 Password hashing regressions', () {
    test('hasher never returns plaintext; verify round-trips', () {
      const pw = 'SecretPass1!';
      final stored = PasswordHasher.hash(pw);
      expect(stored, isNot(pw));
      expect(stored.contains(pw), isFalse);
      expect(PasswordHasher.verify(pw, stored), isTrue);
      expect(PasswordHasher.verify('wrong', stored), isFalse);
      expect(PasswordHasher.verify(pw, 'not-a-hash'), isFalse);
    });
  });

  group('RT-09 OSM free-stack / platform contracts', () {
    test('pubspec keeps flutter_map + latlong2; no google_maps_flutter', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('flutter_map:'), isTrue);
      expect(pubspec.contains('latlong2:'), isTrue);
      expect(pubspec.contains('google_maps_flutter'), isFalse);
    });

    test('Android location + FGS permissions still declared', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('ACCESS_FINE_LOCATION'), isTrue);
      expect(manifest.contains('FOREGROUND_SERVICE'), isTrue);
      expect(
        manifest.contains('FOREGROUND_SERVICE_LOCATION') ||
            manifest.contains('foregroundServiceType'),
        isTrue,
      );
    });

    test('iOS AppDelegate does not initialize Google Maps SDK', () {
      final appDelegate =
          File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(appDelegate.contains('GMSServices'), isFalse);
      expect(appDelegate.contains('GoogleMaps'), isFalse);
    });

    test('MapsService distance stays finite for Gwadar coords', () {
      final svc = MapsService();
      final d = svc.calculateDistance(25.1450, 62.3600, 25.1500, 62.3700);
      expect(d.isFinite, isTrue);
      expect(d, greaterThan(0));
    });

    test('OsmMapView fallback center remains finite Gwadar', () {
      expect(OsmMapView.gwadarFallback.latitude.isFinite, isTrue);
      expect(OsmMapView.gwadarFallback.longitude.isFinite, isTrue);
      expect(OsmMapView.gwadarFallback.latitude, closeTo(25.1450, 0.01));
      expect(OsmMapView.gwadarFallback.longitude, closeTo(62.3600, 0.01));
    });
  });

  group('RT-10 Demo credentials + email domain contracts', () {
    test('demo emails still pass role validators', () {
      expect(AppEmailValidator.validate(DemoCredentials.adminEmail), isNull);
      expect(AppEmailValidator.validate(DemoCredentials.driverEmail), isNull);
      expect(
        AppEmailValidator.validateStudent(DemoCredentials.studentEmail),
        isNull,
      );
    });

    test('student-only domain still rejected for admin/driver', () {
      expect(
        AppEmailValidator.validate('ali@student.ug.edu.pk'),
        isNotNull,
      );
    });
  });

  group('RT-11 Role selection layout (common phone)', () {
    testWidgets('no overflow on 360x800 role selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const MaterialApp(home: RoleSelectionScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Student'), findsWidgets);
      expect(find.textContaining('Driver'), findsWidgets);
      expect(find.textContaining('Admin'), findsWidgets);
    });
  });

  group('RT-12 Firestore rules security contracts (static)', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('allowlisted driver email still present', () {
      expect(rules.contains('isAllowlistedDriver'), isTrue);
      expect(rules.contains('driver@uog.edu.pk'), isTrue);
    });

    test('gps_locations writes still require driverId == auth.uid', () {
      expect(rules.contains('match /gps_locations/{tripId}'), isTrue);
      final blockStart = rules.indexOf('match /gps_locations/{tripId}');
      expect(blockStart, greaterThanOrEqualTo(0));
      final block = rules.substring(blockStart, blockStart + 450);
      expect(block.contains('driverId == request.auth.uid'), isTrue);
    });

    test('roleUnchanged still blocks self role escalation', () {
      expect(rules.contains('roleUnchanged'), isTrue);
    });

    test('_meta seed readable when signed in', () {
      expect(rules.contains('match /_meta/{id}'), isTrue);
    });
  });
}
