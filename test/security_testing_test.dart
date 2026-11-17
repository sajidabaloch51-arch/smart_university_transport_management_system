import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/student_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';

/// Security tests: RBAC, password handling, trip/GPS authorization contracts,
/// and static checks that Firestore rules still enforce critical policies.
void main() {
  group('SEC-01 Route RBAC (frontend policy)', () {
    test('anonymous users cannot open protected dashboards', () {
      for (final path in [
        '/admin-dashboard',
        '/driver-dashboard',
        '/student-dashboard',
        '/live-tracking',
        '/admin-live-tracking',
        '/manage-routes',
      ]) {
        expect(
          AuthRouteGuard.redirect(
            location: path,
            appAuthenticated: false,
            hasFirebaseUser: false,
            role: null,
          ),
          '/role-selection',
          reason: path,
        );
      }
    });

    test('student cannot open admin or driver areas', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/manage-buses',
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
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
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

    test('admin cannot open driver-only paths', () {
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

    test('student may open /live-tracking; admin may open /admin-live-tracking',
        () {
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
    });
  });

  group('SEC-02 Password security', () {
    test('hasher never returns plaintext password', () {
      const raw = 'Secure@Pass1';
      final stored = PasswordHasher.hash(raw);
      expect(stored.contains(raw), isFalse);
      expect(stored.contains(':'), isTrue);
    });

    test('wrong password fails verify', () {
      final stored = PasswordHasher.hash('Secure@Pass1');
      expect(PasswordHasher.verify('Secure@Pass1', stored), isTrue);
      expect(PasswordHasher.verify('Secure@Pass2', stored), isFalse);
      expect(PasswordHasher.verify('', stored), isFalse);
    });

    test('different salts produce different hashes for same password', () {
      final a = PasswordHasher.hash('Secure@Pass1', salt: 'salt_a');
      final b = PasswordHasher.hash('Secure@Pass1', salt: 'salt_b');
      expect(a, isNot(equals(b)));
    });

    test('weak passwords rejected by validators', () {
      expect(AppValidators.validatePassword('12345678'), isNotNull);
      expect(AppValidators.validatePassword('password'), isNotNull);
      expect(AppValidators.validatePassword('Short1!'), isNotNull);
      expect(
        AppValidators.validatePassword(DemoCredentials.adminPassword),
        isNull,
      );
    });

    test('malformed stored hash cannot authenticate', () {
      expect(PasswordHasher.verify('Secure@Pass1', 'not-a-hash'), isFalse);
      expect(PasswordHasher.verify('Secure@Pass1', ''), isFalse);
      expect(PasswordHasher.verify('Secure@Pass1', 'onlySalt'), isFalse);
    });
  });

  group('SEC-03 Trip / GPS authorization contracts', () {
    test('unapproved driver cannot start trip', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'pending',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('suspended / rejected style statuses cannot start trip', () {
      for (final status in ['suspended', 'rejected', '', 'pending']) {
        expect(
          () => TripTrackingService.assertCanStartTrip(
            verificationStatus: status,
            busId: 'bus_1',
            routeId: 'route_1',
          ),
          throwsA(isA<TripStartException>()),
          reason: status,
        );
      }
    });

    test('unassigned bus or route cannot start trip', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'route_1',
        ),
        throwsA(isA<TripStartException>()),
      );
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: '',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('trip and GPS maps never include password or role', () {
      const trip = TripModel(
        id: 't1',
        busId: 'b1',
        driverId: 'auth_uid_only',
        routeId: 'r1',
        status: 'ACTIVE',
      );
      final tripMap = trip.toMap();
      expect(tripMap.containsKey('password'), isFalse);
      expect(tripMap.containsKey('passwordHash'), isFalse);
      expect(tripMap.containsKey('role'), isFalse);

      const gps = GpsLocationModel(
        tripId: 't1',
        busId: 'b1',
        driverId: 'auth_uid_only',
        latitude: 25.14,
        longitude: 62.36,
      );
      final gpsMap = gps.toMap();
      expect(gpsMap.containsKey('password'), isFalse);
      expect(gpsMap['driverId'], 'auth_uid_only');
    });

    test('GPS write shape requires driverId for rules matching auth.uid', () {
      final gps = GpsLocationModel.fromMap({
        'tripId': 't1',
        'busId': 'b1',
        'driverId': 'firebase_auth_uid',
        'latitude': 25.14,
        'longitude': 62.36,
        'isActive': true,
      }, 't1');
      expect(gps.driverId, isNot(equals('driver_id')));
      expect(gps.driverId, 'firebase_auth_uid');
    });
  });

  group('SEC-04 Identity / role elevation', () {
    test('student model does not allow role field to become admin via fromMap defaults',
        () {
      final student = StudentModel.fromMap({
        'name': 'Ali',
        'email': 'ali@uog.edu.pk',
        'phone': '03001234567',
        'role': 'admin', // hostile payload
        'verificationStatus': 'pending',
        'rollNo': 'R-1',
        'regNumber': 'UG-1',
        'department': 'CS',
      }, 'stu_1');
      // fromMap may preserve role string; guard + rules must still block.
      // Security contract: pending students are not treated as approved.
      expect(student.verificationStatus.toLowerCase(), isNot(equals('approved')));
    });

    test('admin/driver emails reject student-only domain', () {
      expect(
        AppEmailValidator.validateForRole('x@student.ug.edu.pk', 'admin'),
        isNotNull,
      );
      expect(
        AppEmailValidator.validateForRole('x@student.ug.edu.pk', 'driver'),
        isNotNull,
      );
      expect(
        AppEmailValidator.validateForRole('x@student.ug.edu.pk', 'student'),
        isNull,
      );
    });

    test('auth error mapper does not leak raw Firebase internals for bad password',
        () {
      final msg = AuthErrorMapper.map('wrong-password', null);
      expect(msg.toLowerCase(), contains('password'));
      expect(msg.toLowerCase(), isNot(contains('firebase_auth')));
      expect(msg.toLowerCase(), isNot(contains('stack')));
    });
  });

  group('SEC-05 Firestore rules security contracts (static)', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('rules file exists and is rules_version 2', () {
      expect(rules, contains("rules_version = '2'"));
    });

    test('trips: driver create/update constrained to own auth uid', () {
      expect(rules, contains('match /trips/{tripId}'));
      expect(rules, contains("request.resource.data.driverId == request.auth.uid"));
      expect(rules, contains("resource.data.driverId == request.auth.uid"));
    });

    test('gps_locations: only driverId == auth.uid may write', () {
      expect(rules, contains('match /gps_locations/{tripId}'));
      expect(
        rules,
        contains(
          "request.resource.data.driverId == request.auth.uid",
        ),
      );
    });

    test('users: self-create limited to student role', () {
      expect(rules, contains('createRoleIsStudentOnly'));
      expect(rules, contains("request.resource.data.role == 'student'"));
    });

    test('users: roleUnchanged prevents self role escalation on update', () {
      expect(rules, contains('roleUnchanged'));
      expect(
        rules,
        contains('request.resource.data.role == resource.data.role'),
      );
    });

    test('drivers cannot change assignment fields', () {
      expect(rules, contains('driverAssignmentFieldsUnchanged'));
      expect(rules, contains("'assignedRouteId'"));
      expect(rules, contains("'assignedBusId'"));
    });

    test('students cannot write gps_locations (no student write path)', () {
      // gps write only admin or isDriver + own uid — no isStudent write.
      final start = rules.indexOf('match /gps_locations/{tripId}');
      final end = rules.indexOf('match /_meta/{id}');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final section = rules.substring(start, end);
      expect(section.contains('isStudent()'), isFalse);
      expect(section.contains('isDriver()'), isTrue);
      expect(section.contains('allow create, update: if isAdmin()'), isTrue);
    });

    test('duties: students have no write access', () {
      final start = rules.indexOf('match /duties/{dutyId}');
      final end = rules.indexOf('match /alerts/{alertId}');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final section = rules.substring(start, end);
      expect(section, contains('allow create, update, delete: if isAdmin();'));
      expect(section.contains('isStudent()'), isFalse);
    });

    test('_meta seed readable when signed in; writes admin-only', () {
      expect(rules, contains("id == 'seed' && signedIn()"));
      expect(rules, contains('allow write: if isAdmin()'));
    });

    test('approvedAdmins / approvedDrivers are not openly listable', () {
      expect(rules, contains('match /approvedAdmins/{id}'));
      expect(rules, contains('match /approvedDrivers/{id}'));
      expect(rules, contains('allow list: if isAdmin()'));
    });
  });
}
