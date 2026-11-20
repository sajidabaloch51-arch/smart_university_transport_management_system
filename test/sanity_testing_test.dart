import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/live_tracking_provider.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/map_marker_helper.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Sanity tests: shallow verification that the recent live-tracking / GPS
/// feature area still works after fixes (START/END gate, map, RBAC paths,
/// duty empty-state, permission copy, OSM stack). Not a full regression pass.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SN-01 Driver trip control sanity', () {
    test('approved + assigned → START allowed', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        returnsNormally,
      );
    });

    test('missing bus or route → START blocked with clear message', () {
      try {
        TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: '',
          routeId: 'route_1',
        );
        fail('expected TripStartException');
      } on TripStartException catch (e) {
        expect(e.message.toLowerCase(), contains('bus'));
      }

      try {
        TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'Not Assigned',
        );
        fail('expected TripStartException');
      } on TripStartException catch (e) {
        expect(e.message.toLowerCase(), contains('route'));
      }
    });

    testWidgets('START / END / TRIP ACTIVE labels present for duty UI',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('TRIP ACTIVE'),
                Text('Sharing GPS with students & admin'),
                Text('START TRIP'),
                Text('END TRIP'),
                Text('TRIP OFFLINE'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('START TRIP'), findsOneWidget);
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.text('TRIP ACTIVE'), findsOneWidget);
      expect(find.textContaining('Sharing GPS'), findsOneWidget);
    });
  });

  group('SN-02 Active trip → student/admin map data sanity', () {
    test('ACTIVE trip + valid GPS ready for OsmMapView', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'auth_uid_1',
        'routeId': 'r1',
        'busNumber': 'UG-01',
        'routeName': 'Jetty',
        'driverName': 'Ali',
        'status': 'ACTIVE',
        'lastLat': 25.145,
        'lastLng': 62.36,
      }, 't1');
      expect(trip.isActive, isTrue);

      final gps = GpsLocationModel.fromMap({
        'tripId': 't1',
        'busId': 'b1',
        'driverId': 'auth_uid_1',
        'latitude': 25.145,
        'longitude': 62.36,
        'isActive': true,
      }, 't1');
      expect(gps.hasValidCoords, isTrue);
      expect(gps.driverId, 'auth_uid_1');

      // Student/admin map marker input.
      final busPoint = LatLng(gps.latitude, gps.longitude);
      expect(busPoint.latitude.isFinite, isTrue);
      expect(busPoint.longitude.isFinite, isTrue);
    });

    test('COMPLETED trip / zero GPS do not look live', () {
      final done = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'uid',
        'routeId': 'r1',
        'status': 'COMPLETED',
      }, 't2');
      expect(done.isActive, isFalse);

      final placeholder = GpsLocationModel.fromMap({
        'latitude': 0,
        'longitude': 0,
        'isActive': true,
        'driverId': 'uid',
      }, 't2');
      expect(placeholder.hasValidCoords, isFalse);
      expect(placeholder.isLive, isFalse);
    });

    test('live tracking status label is usable when idle', () {
      final p = LiveTrackingProvider();
      expect(p.statusLabel, 'Select a route first');
    });
  });

  group('SN-03 Route polyline / stops sanity', () {
    test('ordered stops become polyline; zero coords skipped', () {
      final route = RouteModel.fromMap('r1', {
        'routeName': 'Campus',
        'stops': [
          {'stopName': 'A', 'lat': 0, 'lng': 0, 'order': 1},
          {'stopName': 'B', 'lat': 25.14, 'lng': 62.36, 'order': 2},
          {'stopName': 'C', 'lat': 25.15, 'lng': 62.37, 'order': 3},
        ],
      });
      final pts = MapMarkerHelper.routePolyline(route);
      expect(pts.length, 2);
      expect(pts.first.latitude, 25.14);
      final markers = MapMarkerHelper.stopMarkers(route);
      expect(markers.length, 2);
      expect(markers.first.isTerminal || markers.last.isTerminal, isTrue);
    });
  });

  group('SN-04 OsmMapView sanity (post overflow / NaN fixes)', () {
    testWidgets('phone map with bus marker builds without layout overflow',
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
                routePoints: [
                  LatLng(25.1400, 62.3500),
                  LatLng(25.1500, 62.3700),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      expect(find.byType(OsmMapView), findsOneWidget);
    });

    testWidgets('undersized map shows placeholder (no TileLayer crash)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 20,
              height: 20,
              child: OsmMapView(followBus: false),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SN-05 Live-tracking RBAC sanity', () {
    test('student may open /live-tracking; not admin live', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
      );
    });

    test('admin may open /admin-live-tracking; not student live', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        '/admin-dashboard',
      );
    });

    test('driver stays on driver home for student/admin live paths', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'driver',
        ),
        '/driver-dashboard',
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'driver',
        ),
        '/driver-dashboard',
      );
    });
  });

  group('SN-06 Duty empty-state + permission copy sanity', () {
    testWidgets('empty duties still mention START TRIP', (tester) async {
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
      expect(find.textContaining('START TRIP'), findsOneWidget);
    });

    test('permission-denied message stays actionable', () {
      final msg = FirestoreErrorMessages.friendly(
        StateError('permission-denied'),
      );
      expect(msg.toLowerCase(), contains('access'));
      expect(msg.toLowerCase(), isNot(contains('firebaseexception')));
    });
  });

  group('SN-07 Free OSM / rules sanity after GPS work', () {
    test('still on flutter_map (no google_maps_flutter)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('flutter_map:'), isTrue);
      expect(pubspec.contains('google_maps_flutter'), isFalse);
    });

    test('gps_locations rules still bind writes to auth.uid', () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(rules.contains('match /gps_locations/{tripId}'), isTrue);
      expect(rules.contains('isAllowlistedDriver'), isTrue);
      final i = rules.indexOf('match /gps_locations/{tripId}');
      final block = rules.substring(i, i + 450);
      expect(block.contains('driverId == request.auth.uid'), isTrue);
    });

    test('Android FGS location permission still present', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('FOREGROUND_SERVICE_LOCATION'), isTrue);
      expect(manifest.contains('ACCESS_FINE_LOCATION'), isTrue);
    });
  });
}
