import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/services/trip_tracking_service.dart';

/// Focused unit tests for Free OSM + Firestore live bus tracking (no GPS hardware).
void main() {
  group('TripModel parse', () {
    test('fromMap normalizes status and fields', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'd1',
        'routeId': 'r1',
        'busNumber': 'UG-01',
        'routeName': 'Campus Loop',
        'driverName': 'Ali',
        'status': 'active',
        'lastLat': 25.14,
        'lastLng': 62.36,
      }, 't1');

      expect(trip.id, 't1');
      expect(trip.status, 'ACTIVE');
      expect(trip.isActive, isTrue);
      expect(trip.busNumber, 'UG-01');
      expect(trip.lastLat, 25.14);
      expect(trip.lastLng, 62.36);
    });

    test('COMPLETED is not active', () {
      final trip = TripModel.fromMap({
        'busId': 'b1',
        'driverId': 'd1',
        'routeId': 'r1',
        'status': 'COMPLETED',
      }, 't2');
      expect(trip.isActive, isFalse);
    });

    test('toMap keeps required assignment fields', () {
      const trip = TripModel(
        id: 't3',
        busId: 'b1',
        driverId: 'd1',
        routeId: 'r1',
        busNumber: 'UG-02',
        routeName: 'Jetty',
        driverName: 'Sara',
        status: 'ACTIVE',
      );
      final map = trip.toMap();
      expect(map.keys, containsAll(['busId', 'driverId', 'routeId', 'status']));
      expect(map['status'], 'ACTIVE');
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('role'), isFalse);
    });
  });

  group('GpsLocationModel parse', () {
    test('fromMap accepts lat/lng aliases and defaults', () {
      final gps = GpsLocationModel.fromMap({
        'busId': 'b1',
        'driverId': 'd1',
        'lat': 25.1,
        'lng': 62.3,
        'speed': 12.5,
        'heading': 90,
        'isActive': true,
      }, 't1');

      expect(gps.tripId, 't1');
      expect(gps.latitude, 25.1);
      expect(gps.longitude, 62.3);
      expect(gps.hasValidCoords, isTrue);
      expect(gps.isActive, isTrue);
    });

    test('zero coords are not valid / not live', () {
      final gps = GpsLocationModel.fromMap({
        'tripId': 't1',
        'busId': 'b1',
        'driverId': 'd1',
        'latitude': 0,
        'longitude': 0,
        'isActive': true,
      }, 't1');
      expect(gps.hasValidCoords, isFalse);
      expect(gps.isLive, isFalse);
    });

    test('toMap shape for Firestore upsert', () {
      const gps = GpsLocationModel(
        tripId: 't1',
        busId: 'b1',
        driverId: 'd1',
        latitude: 25.14,
        longitude: 62.36,
        speed: 5,
        heading: 180,
      );
      final map = gps.toMap();
      expect(
        map.keys,
        containsAll([
          'tripId',
          'busId',
          'driverId',
          'latitude',
          'longitude',
          'speed',
          'heading',
          'isActive',
        ]),
      );
      expect(map.containsKey('password'), isFalse);
    });
  });

  group('Trip start gate', () {
    test('rejects unapproved driver', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'b1',
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('rejects missing bus assignment', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('rejects missing route assignment', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'b1',
          routeId: '',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('allows approved driver with bus and route', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'b1',
          routeId: 'r1',
        ),
        returnsNormally,
      );
    });
  });

  group('idsMatch / matchActiveTrip', () {
    test('matches UOG-01 with uog-001 and separators', () {
      expect(TripTrackingService.idsMatch('UOG-01', 'uog-001'), isTrue);
      expect(TripTrackingService.idsMatch('UOG 01', 'uog001'), isTrue);
      expect(TripTrackingService.idsMatch('UOG-01', 'UOG-02'), isFalse);
      expect(TripTrackingService.idsMatch('', 'uog-001'), isFalse);
    });

    test('prefers routeId then bus then driver', () {
      final trips = [
        TripModel.fromMap({
          'busId': 'other-bus',
          'busNumber': 'UOG-99',
          'driverId': 'd-match',
          'routeId': 'r-other',
          'status': 'ACTIVE',
        }, 't-driver'),
        TripModel.fromMap({
          'busId': 'bus-doc-1',
          'busNumber': 'UOG-01',
          'driverId': 'd2',
          'routeId': 'r-other',
          'status': 'ACTIVE',
        }, 't-bus'),
        TripModel.fromMap({
          'busId': 'x',
          'busNumber': 'Z',
          'driverId': 'd3',
          'routeId': 'route-sarawan',
          'status': 'ACTIVE',
        }, 't-route'),
      ];

      expect(
        TripTrackingService.matchActiveTrip(
          trips,
          routeId: 'route-sarawan',
          busId: 'bus-doc-1',
          busNumber: 'uog-001',
          driverId: 'd-match',
        )?.id,
        't-route',
      );
      expect(
        TripTrackingService.matchActiveTrip(
          trips,
          busNumber: 'uog-001',
          driverId: 'd-match',
        )?.id,
        't-bus',
      );
      expect(
        TripTrackingService.matchActiveTrip(
          trips,
          driverId: 'd-match',
        )?.id,
        't-driver',
      );
    });
  });

  group('AuthRouteGuard admin live tracking', () {
    test('guards /admin-live-tracking for non-admins', () {
      expect(AuthRouteGuard.isAdminPath('/admin-live-tracking'), isTrue);
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
}

/// Manual two-phone UAT checklist (Android):
/// 1. Driver (approved + assigned bus/route): START TRIP → Firestore trips ACTIVE + gps_locations.
/// 2. Student on same bus/route: /live-tracking shows OSM bus marker moving.
/// 3. Admin: /admin-live-tracking lists trip; select → live map.
/// 4. Driver END TRIP → GPS stops; student sees inactive message.
/// 5. Deny location permission / GPS off / offline → honest SnackBars; no publish when not ACTIVE.
