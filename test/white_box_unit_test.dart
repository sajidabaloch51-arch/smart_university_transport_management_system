import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/models/driver_model.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/student_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/providers/live_tracking_provider.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/firestore_parse.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/utils/map_marker_helper.dart';

/// White-box unit tests: exercise internal branches and edge cases.
void main() {
  group('WB-01 AuthRouteGuard.redirect', () {
    test('public paths stay open when logged out', () {
      for (final path in AuthRouteGuard.publicPaths) {
        expect(
          AuthRouteGuard.redirect(
            location: path,
            appAuthenticated: false,
            hasFirebaseUser: false,
            role: null,
          ),
          isNull,
          reason: path,
        );
      }
    });

    test('protected path redirects logged-out user to role-selection', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-dashboard',
          appAuthenticated: false,
          hasFirebaseUser: false,
          role: null,
        ),
        '/role-selection',
      );
    });

    test('student cannot open admin paths', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/manage-students',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
      );
    });

    test('driver cannot open student paths', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/student-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'driver',
        ),
        '/driver-dashboard',
      );
    });

    test('admin cannot open driver paths', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/driver-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        '/admin-dashboard',
      );
    });

    test('authenticated user leaving login goes home for role', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/login',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        '/admin-dashboard',
      );
    });

    test('firebase-only session without appAuthenticated can stay on login', () {
      // Splash still owns session restore; guard does not bounce early.
      expect(
        AuthRouteGuard.redirect(
          location: '/login',
          appAuthenticated: false,
          hasFirebaseUser: true,
          role: null,
        ),
        isNull,
      );
    });

    test('homeForRole defaults to student', () {
      expect(AuthRouteGuard.homeForRole(null), '/student-dashboard');
      expect(AuthRouteGuard.homeForRole('ADMIN'), '/admin-dashboard');
    });

    test('admin-live-tracking is an admin path', () {
      expect(AuthRouteGuard.isAdminPath('/admin-live-tracking'), isTrue);
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
      );
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
  });

  group('WB-02 AuthRoleResolver', () {
    test('prefers uid role over email and prefs', () {
      expect(
        AuthRoleResolver.resolve(
          firestoreRoleByUid: 'admin',
          firestoreRoleByEmail: 'student',
          prefsRole: 'driver',
        ),
        'admin',
      );
    });

    test('falls back through email then prefs then student', () {
      expect(
        AuthRoleResolver.resolve(
          firestoreRoleByUid: null,
          firestoreRoleByEmail: 'Driver',
          prefsRole: 'admin',
        ),
        'driver',
      );
      expect(
        AuthRoleResolver.resolve(
          firestoreRoleByUid: '',
          firestoreRoleByEmail: 'nope',
          prefsRole: 'student',
        ),
        'student',
      );
      expect(
        AuthRoleResolver.resolve(
          firestoreRoleByUid: null,
          firestoreRoleByEmail: null,
          prefsRole: null,
        ),
        'student',
      );
    });

    test('needsRoleMirror only when ids differ and role valid', () {
      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: 'auth1',
          profileUid: 'admin_id',
          role: 'admin',
        ),
        isTrue,
      );
      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: 'auth1',
          profileUid: 'auth1',
          role: 'admin',
        ),
        isFalse,
      );
      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: 'auth1',
          profileUid: 'admin_id',
          role: 'boss',
        ),
        isFalse,
      );
    });
  });

  group('WB-03 PasswordHasher', () {
    test('hash then verify succeeds', () {
      final stored = PasswordHasher.hash('Admin@1234');
      expect(PasswordHasher.verify('Admin@1234', stored), isTrue);
      expect(PasswordHasher.verify('wrong', stored), isFalse);
    });

    test('same password different salts produce different hashes', () {
      final a = PasswordHasher.hash('Secret@123');
      final b = PasswordHasher.hash('Secret@123');
      expect(a, isNot(equals(b)));
      expect(PasswordHasher.verify('Secret@123', a), isTrue);
      expect(PasswordHasher.verify('Secret@123', b), isTrue);
    });

    test('malformed stored string fails verify', () {
      expect(PasswordHasher.verify('x', 'not-a-hash'), isFalse);
    });
  });

  group('WB-04 FirestoreParse', () {
    test('asString / asInt / asBool tolerant', () {
      expect(FirestoreParse.asString(null), '');
      expect(FirestoreParse.asString(12), '12');
      expect(FirestoreParse.asInt('42'), 42);
      expect(FirestoreParse.asInt(null), isNull);
      expect(FirestoreParse.asBool('yes'), isTrue);
      expect(FirestoreParse.asBool(0), isFalse);
    });

    test('asDateTime handles Timestamp-like ints and strings', () {
      final fromMillis = FirestoreParse.asDateTime(1700000000000);
      expect(fromMillis, isNotNull);
      expect(FirestoreParse.asDateTime('2024-01-02T03:04:05Z'), isNotNull);
      expect(FirestoreParse.asDateTime(''), isNull);
    });

    test('asStringList skips nulls', () {
      expect(
        FirestoreParse.asStringList([null, 'a', 1]),
        ['a', '1'],
      );
    });
  });

  group('WB-05 Model fromMap tolerance', () {
    test('StudentModel ignores bad types and legacy keys', () {
      final s = StudentModel.fromMap({
        'name': 123,
        'email': null,
        'fatherName': 'legacy',
        'semester': 8,
        'verificationStatus': 'APPROVED',
        'termsAccepted': 1,
      }, 'uid1');
      expect(s.uid, 'uid1');
      expect(s.name, '123');
      expect(s.email, '');
      expect(s.role, 'student');
      expect(s.verificationStatus.toLowerCase(), 'approved');
    });

    test('DriverModel tolerates string dates and missing fields', () {
      final d = DriverModel.fromMap({
        'name': 'D',
        'licenseExpiryDate': '2025-01-01T00:00:00Z',
        'isOnDuty': 'true',
        'experienceYears': '5',
      }, 'drv1');
      expect(d.uid, 'drv1');
      expect(d.role, 'driver');
      expect(d.experienceYears, 5);
      expect(d.licenseExpiryDate, isNotNull);
    });

    test('RouteModel tolerates malformed stops list', () {
      final r = RouteModel.fromMap('r1', {
        'routeName': 'Campus',
        'stops': [
          {'stopName': 'A', 'timeLabel': '07:00'},
          'bad',
          42,
        ],
        'viaStops': ['X', null, 3],
        'isActive': false,
      });
      expect(r.id, 'r1');
      expect(r.stops.length, 1);
      expect(r.viaStops, ['X', '3']);
      expect(r.isActive, isFalse);
    });
  });

  group('WB-06 FirestoreErrorMessages', () {
    test('maps unauthenticated StateError', () {
      final err = FirestoreQueryException(
        collection: 'users',
        query: 'users_students',
        authUid: null,
        cause: StateError('Please log in again to load data.'),
      );
      expect(FirestoreErrorMessages.friendly(err), 'Please log in again');
      expect(
        FirestoreErrorMessages.debugDetails(err),
        contains('collection=users'),
      );
    });

    test('maps TimeoutException to server message', () {
      expect(
        FirestoreErrorMessages.friendly(
          TimeoutException('slow'),
        ),
        "Can't reach the server",
      );
    });
  });

  group('WB-07 AuthProvider state', () {
    test('setAuthenticated and cacheProfile update fields', () {
      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: 'admin',
        uid: 'u1',
        email: 'a@uog.edu.pk',
      );
      expect(auth.isAuthenticated, isTrue);
      expect(auth.userRole, 'admin');
      expect(auth.uid, 'u1');
      auth.cacheProfile(displayName: 'Admin', role: 'admin');
      expect(auth.displayName, 'Admin');
    });
  });

  group('WB-08 TripTrackingService.assertCanStartTrip branches', () {
    test('covers pending / empty / not-assigned / approved paths', () {
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
          busId: null,
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );

      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: '  ',
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
        throwsA(
          isA<TripStartException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('bus'),
          ),
        ),
      );

      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'b1',
          routeId: 'not assigned',
        ),
        throwsA(
          isA<TripStartException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('route'),
          ),
        ),
      );

      // Case-insensitive approved status.
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'APPROVED',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        returnsNormally,
      );
    });
  });

  group('WB-09 TripModel / GpsLocationModel internal branches', () {
    test('status normalization and isActive branch', () {
      expect(
        TripModel.fromMap({
          'busId': 'b',
          'driverId': 'd',
          'routeId': 'r',
          'status': 'active',
        }, 't1').isActive,
        isTrue,
      );
      expect(
        TripModel.fromMap({
          'busId': 'b',
          'driverId': 'd',
          'routeId': 'r',
          'status': 'completed',
        }, 't2').isActive,
        isFalse,
      );
      expect(
        TripModel.fromMap({
          'busId': 'b',
          'driverId': 'd',
          'routeId': 'r',
        }, 't3').status,
        'ACTIVE',
      );
    });

    test('GPS lat/lng aliases, hasValidCoords, isLive freshness', () {
      final viaAlias = GpsLocationModel.fromMap({
        'busId': 'b1',
        'driverId': 'd1',
        'lat': 25.1,
        'lng': 62.3,
        'isActive': true,
      }, 't1');
      expect(viaAlias.latitude, 25.1);
      expect(viaAlias.longitude, 62.3);
      expect(viaAlias.hasValidCoords, isTrue);

      final zeros = GpsLocationModel.fromMap({
        'latitude': 0,
        'longitude': 0,
        'isActive': true,
        'driverId': 'd1',
      }, 't2');
      expect(zeros.hasValidCoords, isFalse);
      expect(zeros.isLive, isFalse);

      final inactive = GpsLocationModel.fromMap({
        'latitude': 25.1,
        'longitude': 62.3,
        'isActive': false,
        'driverId': 'd1',
      }, 't3');
      expect(inactive.isLive, isFalse);

      final map = viaAlias.toMap();
      expect(map['driverId'], 'd1');
      expect(map.containsKey('password'), isFalse);
    });
  });

  group('WB-10 MapMarkerHelper internal filtering', () {
    test('skips zero stops; marks terminals; sorts by order', () {
      final route = RouteModel.fromMap('r1', {
        'routeName': 'Loop',
        'stops': [
          {'stopName': 'C', 'lat': 25.16, 'lng': 62.38, 'order': 3},
          {'stopName': 'Bad', 'lat': 0, 'lng': 0, 'order': 2},
          {'stopName': 'A', 'lat': 25.14, 'lng': 62.36, 'order': 1},
        ],
      });
      final pts = MapMarkerHelper.routePolyline(route);
      expect(pts.length, 2);
      expect(pts.first.latitude, 25.14);
      expect(pts.last.latitude, 25.16);

      final markers = MapMarkerHelper.stopMarkers(route);
      expect(markers.length, 2);
      expect(markers.first.label, 'A');
      expect(markers.first.isTerminal, isTrue);
      expect(markers.last.isTerminal, isTrue);
    });

    test('null route returns empty lists', () {
      expect(MapMarkerHelper.routePolyline(null), isEmpty);
      expect(MapMarkerHelper.stopMarkers(null), isEmpty);
    });
  });

  group('WB-11 LiveTrackingProvider statusLabel branches', () {
    test('idle provider reports select-route label', () {
      final p = LiveTrackingProvider();
      expect(p.statusLabel, 'Select a route first');
      expect(p.isBusLive, isFalse);
      expect(p.busNumber, '—');
    });
  });

  group('WB-12 Live-tracking path classification branches', () {
    test('student live vs admin live path helpers', () {
      expect(AuthRouteGuard.isStudentPath('/live-tracking'), isTrue);
      expect(AuthRouteGuard.isAdminPath('/live-tracking'), isFalse);
      expect(AuthRouteGuard.isAdminPath('/admin-live-tracking'), isTrue);
      expect(AuthRouteGuard.isStudentPath('/admin-live-tracking'), isFalse);
      expect(AuthRouteGuard.isDriverPath('/driver-dashboard'), isTrue);
      expect(AuthRouteGuard.isDriverPath('/live-tracking'), isFalse);
    });

    test('permission-denied string branch maps to access message', () {
      final msg = FirestoreErrorMessages.friendly(
        StateError('permission-denied for users'),
      );
      expect(msg.toLowerCase(), contains('access'));
    });
  });
}
