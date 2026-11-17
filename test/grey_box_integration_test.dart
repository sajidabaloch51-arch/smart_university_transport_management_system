import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/driver_model.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/student_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/utils/map_marker_helper.dart';

/// Grey-box tests: know internal layers (validators, hasher, role mirror,
/// route guard, error mappers, Firestore wire maps) but assert end-to-end
/// outcomes the UI / login / splash pipeline depends on.
void main() {
  group('GB-01 Demo login form pipeline', () {
    for (final case_ in [
      (
        role: 'admin',
        email: DemoCredentials.adminEmail,
        password: DemoCredentials.adminPassword,
        home: '/admin-dashboard',
      ),
      (
        role: 'driver',
        email: DemoCredentials.driverEmail,
        password: DemoCredentials.driverPassword,
        home: '/driver-dashboard',
      ),
      (
        role: 'student',
        email: DemoCredentials.studentEmail,
        password: DemoCredentials.studentPassword,
        home: '/student-dashboard',
      ),
    ]) {
      test('${case_.role}: validate → hash → home route', () {
        final emailErr = AppValidators.validateEmailForRole(
          case_.email,
          case_.role,
        );
        final passErr = AppValidators.validatePassword(case_.password);
        expect(emailErr, isNull, reason: case_.email);
        expect(passErr, isNull, reason: case_.password);

        final stored = PasswordHasher.hash(case_.password);
        expect(PasswordHasher.verify(case_.password, stored), isTrue);
        expect(PasswordHasher.verify('${case_.password}x', stored), isFalse);

        expect(AuthRouteGuard.homeForRole(case_.role), case_.home);
      });
    }

    test('student-only domain rejected for driver login path', () {
      expect(
        AppValidators.validateEmailForRole(
          'ali@student.ug.edu.pk',
          'driver',
        ),
        isNotNull,
      );
      expect(
        AppValidators.validateEmailForRole(
          'ali@student.ug.edu.pk',
          'student',
        ),
        isNull,
      );
    });
  });

  group('GB-02 Session restore (Auth uid ≠ seed doc id)', () {
    test('mirror + resolve + guard opens admin dashboard lists', () {
      const authUid = 'firebaseAuthUidAbc';
      const seedDocId = 'admin_id';

      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: authUid,
          profileUid: seedDocId,
          role: 'admin',
        ),
        isTrue,
      );

      final role = AuthRoleResolver.resolve(
        firestoreRoleByUid: null, // mirror not written yet
        firestoreRoleByEmail: 'admin',
        prefsRole: 'student', // stale prefs must not win
      );
      expect(role, 'admin');

      final auth = AuthProvider();
      auth.setAuthenticated(true, role: role, uid: authUid, email: DemoCredentials.adminEmail);

      expect(
        AuthRouteGuard.redirect(
          location: '/manage-students',
          appAuthenticated: auth.isAuthenticated,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/student-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        '/admin-dashboard',
      );
    });

    test('after mirror exists on Auth uid, resolve prefers uid role', () {
      final role = AuthRoleResolver.resolve(
        firestoreRoleByUid: 'driver',
        firestoreRoleByEmail: 'admin',
        prefsRole: 'student',
      );
      expect(role, 'driver');
      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: 'same',
          profileUid: 'same',
          role: 'driver',
        ),
        isFalse,
      );
    });
  });

  group('GB-03 Unauthenticated LiveFirestore → UI message', () {
    test('authUid=null StateError becomes Please log in again + details', () {
      final err = FirestoreQueryException(
        collection: 'users',
        query: 'users_students',
        authUid: null,
        cause: StateError('Please log in again to load data.'),
      );

      expect(err.isUnauthenticated, isTrue);
      expect(FirestoreErrorMessages.friendly(err), 'Please log in again');

      final details = FirestoreErrorMessages.debugDetails(err);
      expect(details, contains('collection=users'));
      expect(details, contains('query=users_students'));
      expect(details, contains('authUid=null'));
    });

    test('timeout on list load maps to server unreachable', () {
      final err = FirestoreQueryException(
        collection: 'routes',
        query: 'routes_active',
        authUid: 'uid1',
        cause: TimeoutException('Future not completed'),
      );
      expect(
        FirestoreErrorMessages.friendly(err),
        "Can't reach the server",
      );
    });
  });

  group('GB-04 Firestore wire format round-trips', () {
    test('StudentModel toMap → fromMap keeps verification + assignments', () {
      final original = StudentModel(
        uid: 'stu1',
        name: 'Ali Khan',
        email: 'ali@uog.edu.pk',
        phone: '03001234567',
        role: 'student',
        regNumber: 'UG-2024-001',
        department: 'CS',
        rollNo: 'CS-01',
        assignedRouteId: 'route_1',
        assignedRouteName: 'Campus Loop',
        verificationStatus: 'approved',
        termsAccepted: true,
        passwordHash: PasswordHasher.hash('Student@1234'),
      );

      final again = StudentModel.fromMap(original.toMap(), original.uid);
      expect(again.email, original.email);
      expect(again.verificationStatus, 'approved');
      expect(again.assignedRouteId, 'route_1');
      expect(again.termsAccepted, isTrue);
      expect(
        PasswordHasher.verify('Student@1234', again.passwordHash!),
        isTrue,
      );
      // Legacy keys must not be written by lean toMap.
      expect(original.toMap().containsKey('fatherName'), isFalse);
      expect(original.toMap().containsKey('semester'), isFalse);
    });

    test('DriverModel duty + license round-trip', () {
      final original = DriverModel(
        uid: 'drv1',
        name: 'Driver One',
        email: DemoCredentials.driverEmail,
        phone: '03007654321',
        role: 'driver',
        driverId: 'EMP-1',
        licenseExpiryDate: DateTime.utc(2026, 6, 1),
        experienceYears: 5,
        assignedBusId: 'bus1',
        assignedBusNumber: 'UG-01',
        assignedRouteId: 'route_1',
        assignedRouteName: 'Campus Loop',
        isOnDuty: true,
        verificationStatus: 'approved',
      );
      final again = DriverModel.fromMap(original.toMap(), original.uid);
      expect(again.isOnDuty, isTrue);
      expect(again.experienceYears, 5);
      expect(again.assignedRouteId, 'route_1');
      expect(again.email, DemoCredentials.driverEmail);
    });

    test('RouteModel malformed stops still yields usable card labels', () {
      final route = RouteModel.fromMap('r1', {
        'routeName': 'Gwadar Campus',
        'startLocation': 'Jetty',
        'endLocation': 'Campus',
        'departureTime': '07:30 AM',
        'arrivalTime': '08:15 AM',
        'estimatedTime': '45 min',
        'stops': [
          {'stopName': 'Jetty', 'timeLabel': '07:30 AM'},
          'corrupt',
          {'stopName': 'Campus', 'timeLabel': '08:15 AM'},
        ],
        'isActive': true,
      });
      expect(route.stops.length, 2);
      expect(route.cardStartLabel, 'Jetty');
      expect(route.cardEndLabel, 'Campus');
      expect(route.cardDepartureTime, '07:30 AM');
      expect(route.cardDuration, '45 min');
    });
  });

  group('GB-05 Auth error mapping (login UI copy)', () {
    test('credential failures never leak Firebase codes to the user', () {
      for (final code in [
        'wrong-password',
        'invalid-credential',
        'invalid-login-credentials',
        'user-not-found',
      ]) {
        expect(
          AuthErrorMapper.map(code, 'secret firebase detail'),
          'Incorrect email or password.',
        );
      }
    });

    test('detects web-wrapped invalid-credential strings', () {
      final wrapped = Exception(
        '[firebase_auth/invalid-credential] The supplied auth '
        'credential is incorrect, malformed or has expired.',
      );
      expect(AuthErrorMapper.isCredentialMismatch(wrapped), isTrue);
      expect(AuthErrorMapper.isUserMissing(wrapped), isFalse);
    });

    test('configuration errors stay detectable for UI hints', () {
      expect(
        AuthErrorMapper.isConfigurationError(
          Exception('CONFIGURATION_NOT_FOUND'),
        ),
        isTrue,
      );
      expect(
        AuthErrorMapper.map('internal-error', 'CONFIGURATION_NOT_FOUND'),
        contains('Email/Password is not enabled'),
      );
    });
  });

  group('GB-06 Cross-role isolation after login', () {
    test('each role is bounced from foreign dashboards', () {
      const matrix = [
        ('admin', '/driver-dashboard', '/admin-dashboard'),
        ('admin', '/student-home', '/admin-dashboard'),
        ('driver', '/manage-routes', '/driver-dashboard'),
        ('driver', '/feedback', '/driver-dashboard'),
        ('student', '/manage-students', '/student-dashboard'),
        ('student', '/driver-route', '/student-dashboard'),
      ];
      for (final (role, path, home) in matrix) {
        expect(
          AuthRouteGuard.redirect(
            location: path,
            appAuthenticated: true,
            hasFirebaseUser: true,
            role: role,
          ),
          home,
          reason: '$role → $path',
        );
      }
    });

    test('normalize email before shared domain check (login case-fold)', () {
      final raw = '  ${DemoCredentials.adminEmail.toUpperCase()}  ';
      final normalized = AppEmailValidator.normalize(raw);
      expect(AppValidators.validateEmail(normalized), isNull);
      expect(normalized, DemoCredentials.adminEmail);
    });
  });

  group('GB-07 Driver trip pipeline (Auth uid ≠ seed driver_id)', () {
    test('resolve driver → START gate → trip/GPS maps use auth uid', () {
      const authUid = 'firebaseDriverUid';
      const seedDocId = 'driver_id';

      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: authUid,
          profileUid: seedDocId,
          role: 'driver',
        ),
        isTrue,
      );

      final role = AuthRoleResolver.resolve(
        firestoreRoleByUid: null,
        firestoreRoleByEmail: 'driver',
        prefsRole: 'student',
      );
      expect(role, 'driver');

      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: role,
        uid: authUid,
        email: DemoCredentials.driverEmail,
      );

      // Profile may still carry seed assignments; START uses auth uid as driverId.
      final profile = DriverModel(
        uid: seedDocId,
        name: 'Demo Driver',
        email: DemoCredentials.driverEmail,
        phone: '03000000000',
        role: 'driver',
        driverId: 'EMP-SEED',
        assignedBusId: 'bus_1',
        assignedBusNumber: 'UG-01',
        assignedRouteId: 'route_1',
        assignedRouteName: 'Campus Loop',
        isOnDuty: false,
        verificationStatus: 'approved',
      );

      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: profile.verificationStatus,
          busId: profile.assignedBusId,
          routeId: profile.assignedRouteId,
        ),
        returnsNormally,
      );

      final trip = TripModel(
        id: 'trip_new',
        busId: profile.assignedBusId,
        driverId: auth.uid!, // must be Auth uid for rules
        routeId: profile.assignedRouteId,
        busNumber: profile.assignedBusNumber,
        routeName: profile.assignedRouteName,
        driverName: profile.name,
        status: 'ACTIVE',
      );
      expect(trip.driverId, authUid);
      expect(trip.driverId, isNot(seedDocId));
      expect(trip.toMap()['driverId'], authUid);

      final gps = GpsLocationModel(
        tripId: trip.id,
        busId: trip.busId,
        driverId: auth.uid!,
        latitude: 25.145,
        longitude: 62.36,
      );
      expect(gps.toMap()['driverId'], authUid);
      expect(gps.hasValidCoords, isTrue);

      expect(
        AuthRouteGuard.redirect(
          location: '/driver-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        '/driver-dashboard',
      );
    });

    test('unapproved mirrored driver still blocked from START TRIP', () {
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

  group('GB-08 Live tracking student/admin consume pipeline', () {
    test('ACTIVE trip + GPS + route → map LatLngs for OsmMapView', () {
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

      final gps = GpsLocationModel.fromMap({
        'tripId': 't1',
        'busId': 'b1',
        'driverId': 'auth_uid_1',
        'latitude': 25.145,
        'longitude': 62.36,
        'isActive': true,
      }, 't1');

      final route = RouteModel.fromMap('r1', {
        'routeName': 'Jetty',
        'stops': [
          {'stopName': 'Jetty', 'lat': 25.14, 'lng': 62.35, 'order': 1},
          {'stopName': 'Campus', 'lat': 25.15, 'lng': 62.37, 'order': 2},
        ],
      });

      expect(trip.isActive, isTrue);
      expect(gps.hasValidCoords, isTrue);

      final busPoint = LatLng(gps.latitude, gps.longitude);
      final polyline = MapMarkerHelper.routePolyline(route);
      final stops = MapMarkerHelper.stopMarkers(route);

      expect(busPoint.latitude.isFinite, isTrue);
      expect(polyline.length, 2);
      expect(stops.length, 2);
      expect(stops.first.isTerminal, isTrue);
      expect(stops.last.isTerminal, isTrue);
    });

    test('student can open live-tracking; admin opens admin-live-tracking', () {
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
          role: 'admin',
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
  });

  group('GB-09 GPS permission-denied → UI message', () {
    test('gps_locations permission error stays actionable', () {
      final err = FirestoreQueryException(
        collection: 'gps_locations',
        query: 'gps_watch_active',
        authUid: 'uid1',
        cause: StateError('permission-denied'),
      );
      final msg = FirestoreErrorMessages.friendly(err);
      expect(msg.toLowerCase(), contains('access'));
      expect(msg.toLowerCase(), isNot(contains('firebaseexception')));
      expect(
        FirestoreErrorMessages.debugDetails(err),
        contains('collection=gps_locations'),
      );
    });
  });
}
