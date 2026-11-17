import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';

/// Black-box style contract tests: inputs → expected outputs only.
/// No internal Firestore/Auth mocking — validates public validation rules
/// and demo credential shapes the UI expects.
void main() {
  group('BB-01 Student email domains', () {
    test('accepts @uog.edu.pk', () {
      expect(
        AppEmailValidator.validateStudent('ali@uog.edu.pk'),
        isNull,
      );
    });

    test('accepts @gmail.com', () {
      expect(
        AppEmailValidator.validateStudent('ali@gmail.com'),
        isNull,
      );
    });

    test('accepts @student.ug.edu.pk (student panel only)', () {
      expect(
        AppEmailValidator.validateStudent('ali@student.ug.edu.pk'),
        isNull,
      );
    });

    test('rejects @student.ug.edu.pk on admin/driver validator', () {
      expect(
        AppEmailValidator.validate('ali@student.ug.edu.pk'),
        isNotNull,
      );
    });

    test('rejects unknown domain on student panel', () {
      expect(
        AppEmailValidator.validateStudent('ali@yahoo.com'),
        isNotNull,
      );
    });

    test('role helper routes student vs admin correctly', () {
      expect(
        AppEmailValidator.validateForRole('x@student.ug.edu.pk', 'student'),
        isNull,
      );
      expect(
        AppEmailValidator.validateForRole('x@student.ug.edu.pk', 'admin'),
        isNotNull,
      );
    });
  });

  group('BB-02 Demo credentials contract', () {
    test('admin email is university domain', () {
      expect(DemoCredentials.adminEmail.endsWith('@uog.edu.pk'), isTrue);
      expect(AppEmailValidator.validate(DemoCredentials.adminEmail), isNull);
    });

    test('driver email is university domain', () {
      expect(DemoCredentials.driverEmail.endsWith('@uog.edu.pk'), isTrue);
      expect(AppEmailValidator.validate(DemoCredentials.driverEmail), isNull);
    });

    test('student demo email passes student + shared validators', () {
      expect(
        AppEmailValidator.validateStudent(DemoCredentials.studentEmail),
        isNull,
      );
      expect(
        AppEmailValidator.validate(DemoCredentials.studentEmail),
        isNull,
      );
    });

    test('passwords meet minimum length used by login UI', () {
      expect(DemoCredentials.adminPassword.length >= 8, isTrue);
      expect(DemoCredentials.driverPassword.length >= 8, isTrue);
      expect(DemoCredentials.studentPassword.length >= 8, isTrue);
    });
  });

  group('BB-03 Email normalize', () {
    test('trims and lowercases', () {
      expect(
        AppEmailValidator.normalize('  Ali@UOG.EDU.PK '),
        'ali@uog.edu.pk',
      );
    });
  });

  group('BB-04 Live trip public contracts', () {
    test('ACTIVE trip reports isActive true to students/admin UI', () {
      final trip = TripModel.fromMap({
        'busId': 'bus_1',
        'driverId': 'drv_1',
        'routeId': 'route_1',
        'busNumber': 'UG-01',
        'routeName': 'Campus Loop',
        'driverName': 'Demo Driver',
        'status': 'ACTIVE',
      }, 'trip_1');
      expect(trip.isActive, isTrue);
      expect(trip.busNumber, 'UG-01');
      expect(trip.routeName, 'Campus Loop');
    });

    test('COMPLETED trip is not active (empty-state message path)', () {
      final trip = TripModel.fromMap({
        'busId': 'bus_1',
        'driverId': 'drv_1',
        'routeId': 'route_1',
        'status': 'COMPLETED',
      }, 'trip_2');
      expect(trip.isActive, isFalse);
    });

    test('GPS sample with coords is valid for map marker', () {
      final gps = GpsLocationModel.fromMap({
        'tripId': 'trip_1',
        'busId': 'bus_1',
        'driverId': 'drv_1',
        'latitude': 25.1450,
        'longitude': 62.3600,
        'isActive': true,
      }, 'trip_1');
      expect(gps.hasValidCoords, isTrue);
      expect(gps.isActive, isTrue);
    });

    test('zero GPS coords are not treated as a live bus position', () {
      final gps = GpsLocationModel.fromMap({
        'latitude': 0,
        'longitude': 0,
        'isActive': true,
      }, 'trip_1');
      expect(gps.hasValidCoords, isFalse);
      expect(gps.isLive, isFalse);
    });
  });

  group('BB-05 Driver START TRIP gate (observable outcomes)', () {
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

    test('unassigned bus cannot start trip', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'Not Assigned',
          routeId: 'route_1',
        ),
        throwsA(isA<TripStartException>()),
      );
    });

    test('approved + assigned driver may start trip', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'route_1',
        ),
        returnsNormally,
      );
    });
  });

  group('BB-06 Role navigation contracts', () {
    test('student cannot open admin live tracking', () {
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

    test('student can stay on live-tracking', () {
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

    test('driver cannot open student live-tracking', () {
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

    test('admin can open admin-live-tracking', () {
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
}
