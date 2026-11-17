import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/map_marker_helper.dart';

/// Functional tests: feature-level behaviour of live bus tracking flows
/// (START/END gate, trip/GPS contracts, role navigation, map geometry).
/// No live Firebase / device GPS required.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FT-01 Driver START TRIP functional gate', () {
    test('rejects pending verification', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        throwsA(
          isA<TripStartException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('approved'),
          ),
        ),
      );
    });

    test('rejects missing bus assignment', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: '',
          routeId: 'route_1',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('rejects missing route assignment', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'Not Assigned',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('allows approved driver with bus + route', () {
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

  group('FT-02 Trip lifecycle contracts (Student/Admin view)', () {
    test('ACTIVE trip exposes bus, route, driver for live UI', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'auth_uid_1',
        'routeId': 'r1',
        'busNumber': 'UG-07',
        'routeName': 'Jetty Road',
        'driverName': 'Ali',
        'status': 'ACTIVE',
        'lastLat': 25.14,
        'lastLng': 62.36,
      }, 'trip_active');

      expect(trip.isActive, isTrue);
      expect(trip.busNumber, 'UG-07');
      expect(trip.routeName, 'Jetty Road');
      expect(trip.driverName, 'Ali');
      expect(trip.lastLat, 25.14);
      expect(trip.lastLng, 62.36);
    });

    test('COMPLETED trip drives inactive empty state', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'auth_uid_1',
        'routeId': 'r1',
        'status': 'COMPLETED',
      }, 'trip_done');
      expect(trip.isActive, isFalse);
    });

    test('trip toMap never includes password or role elevation fields', () {
      const trip = TripModel(
        id: 't1',
        busId: 'b1',
        driverId: 'd1',
        routeId: 'r1',
        status: 'ACTIVE',
      );
      final map = trip.toMap();
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('role'), isFalse);
      expect(map['driverId'], 'd1');
    });
  });

  group('FT-03 GPS publish contracts', () {
    test('valid coords mark bus marker eligible', () {
      final gps = GpsLocationModel.fromMap({
        'tripId': 't1',
        'busId': 'b1',
        'driverId': 'auth_uid_1',
        'latitude': 25.145,
        'longitude': 62.36,
        'speed': 12,
        'heading': 90,
        'isActive': true,
      }, 't1');
      expect(gps.hasValidCoords, isTrue);
      expect(gps.driverId, 'auth_uid_1');
    });

    test('placeholder 0,0 coords are not shown as live bus', () {
      final gps = GpsLocationModel.fromMap({
        'latitude': 0,
        'longitude': 0,
        'isActive': true,
        'driverId': 'auth_uid_1',
      }, 't1');
      expect(gps.hasValidCoords, isFalse);
      expect(gps.isLive, isFalse);
    });

    test('inactive GPS is not live', () {
      final gps = GpsLocationModel.fromMap({
        'latitude': 25.1,
        'longitude': 62.3,
        'isActive': false,
      }, 't1');
      expect(gps.isLive, isFalse);
    });
  });

  group('FT-04 Route polyline for map', () {
    test('ordered stops become polyline points', () {
      final route = RouteModel.fromMap('r1', {
        'routeName': 'Campus',
        'stops': [
          {'stopName': 'A', 'lat': 25.14, 'lng': 62.36, 'order': 1},
          {'stopName': 'B', 'lat': 25.15, 'lng': 62.37, 'order': 2},
          {'stopName': 'C', 'lat': 25.16, 'lng': 62.38, 'order': 3},
        ],
      });
      final pts = MapMarkerHelper.routePolyline(route);
      expect(pts.length, 3);
      expect(pts.first.latitude, 25.14);
      expect(pts.last.latitude, 25.16);
      final stops = MapMarkerHelper.stopMarkers(route);
      expect(stops.length, 3);
      expect(stops.first.isTerminal, isTrue);
      expect(stops.last.isTerminal, isTrue);
    });

    test('zero-coordinate stops are skipped', () {
      final route = RouteModel.fromMap('r2', {
        'routeName': 'Partial',
        'stops': [
          {'stopName': 'A', 'lat': 0, 'lng': 0, 'order': 1},
          {'stopName': 'B', 'lat': 25.14, 'lng': 62.36, 'order': 2},
        ],
      });
      expect(MapMarkerHelper.routePolyline(route).length, 1);
    });
  });

  group('FT-05 Role-based live tracking access', () {
    testWidgets('student reaches /live-tracking; blocked from admin live',
        (tester) async {
      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: 'student',
        uid: 'stu1',
        email: 's@uog.edu.pk',
      );
      final router = GoRouter(
        initialLocation: '/live-tracking',
        refreshListenable: auth,
        redirect: (context, state) => AuthRouteGuard.redirect(
          location: state.matchedLocation,
          appAuthenticated: auth.isAuthenticated,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
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

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_LIVE'), findsOneWidget);

      router.go('/admin-live-tracking');
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_HOME'), findsOneWidget);
    });

    testWidgets('admin can open /admin-live-tracking', (tester) async {
      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: 'admin',
        uid: 'adm1',
        email: 'admin@uog.edu.pk',
      );
      final router = GoRouter(
        initialLocation: '/admin-live-tracking',
        refreshListenable: auth,
        redirect: (context, state) => AuthRouteGuard.redirect(
          location: state.matchedLocation,
          appAuthenticated: auth.isAuthenticated,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        routes: [
          GoRoute(
            path: '/admin-live-tracking',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_LIVE')),
          ),
          GoRoute(
            path: '/admin-dashboard',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_HOME')),
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
      expect(find.text('ADMIN_LIVE'), findsOneWidget);
    });

    test('driver is redirected away from student live-tracking', () {
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
  });
}
