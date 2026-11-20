import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/route_clock_time.dart';

/// Boundary Value Testing: min / just-below / just-above / max edges for
/// validators, GPS freshness, clocks, and trip start gates.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BVT-01 Password length boundaries (8..20)', () {
    // Strong content; only length varies at the edges.
    String strong(int len) {
      // Pattern cycles to satisfy upper/lower/digit/special while hitting length.
      const base = 'Ab1!Ab1!Ab1!Ab1!Ab1!'; // 20 chars
      return base.substring(0, len);
    }

    test('length 7 rejected; 8 accepted', () {
      expect(AppValidators.validatePassword(strong(7)), isNotNull);
      expect(AppValidators.validatePassword(strong(8)), isNull);
    });

    test('length 20 accepted; 21 rejected', () {
      expect(AppValidators.validatePassword(strong(20)), isNull);
      expect(
        AppValidators.validatePassword('${strong(20)}x'),
        isNotNull,
      );
    });
  });

  group('BVT-02 Experience years (0..50)', () {
    test('just below / min / max / just above', () {
      expect(AppValidators.validateExperienceYears('-1'), isNotNull);
      expect(AppValidators.validateExperienceYears('0'), isNull);
      expect(AppValidators.validateExperienceYears('50'), isNull);
      expect(AppValidators.validateExperienceYears('51'), isNotNull);
    });
  });

  group('BVT-03 Roll number min length (2)', () {
    test('1 char rejected; 2 chars accepted', () {
      expect(AppValidators.validateRollNo('A'), isNotNull);
      expect(AppValidators.validateRollNo('AB'), isNull);
      expect(AppValidators.validateRollNo('01'), isNull);
    });
  });

  group('BVT-04 Phone digit length (11 local)', () {
    test('10 digits rejected; 11 accepted; 12 rejected', () {
      expect(AppValidators.validatePhone('0300123456'), isNotNull); // 10
      expect(AppValidators.validatePhone('03001234567'), isNull); // 11
      expect(AppValidators.validatePhone('030012345678'), isNotNull); // 12
    });
  });

  group('BVT-05 CNIC digit length (13)', () {
    test('12 digits rejected; 13 accepted; 14 rejected', () {
      expect(AppValidators.validateCNIC('123451234567'), isNotNull); // 12
      expect(AppValidators.validateCNIC('1234512345671'), isNull); // 13
      expect(AppValidators.validateCNIC('12345123456712'), isNotNull); // 14
      expect(AppValidators.validateCNIC('12345-1234567-1'), isNull);
    });
  });

  group('BVT-06 Employee ID ### digits', () {
    test('2 digits rejected; 3 accepted; 4 rejected', () {
      expect(AppValidators.validateEmployeeId('UOG-EMP-01'), isNotNull);
      expect(AppValidators.validateEmployeeId('UOG-EMP-001'), isNull);
      expect(AppValidators.validateEmployeeId('UOG-EMP-0001'), isNotNull);
    });
  });

  group('BVT-07 License number digit span (4..12)', () {
    test('3 digits rejected; 4 and 12 accepted; 13 rejected', () {
      expect(AppValidators.validateBalochistanLicense('GAW-123'), isNotNull);
      expect(AppValidators.validateBalochistanLicense('GAW-1234'), isNull);
      expect(
        AppValidators.validateBalochistanLicense('GAW-123456789012'),
        isNull,
      );
      expect(
        AppValidators.validateBalochistanLicense('GAW-1234567890123'),
        isNotNull,
      );
    });
  });

  group('BVT-08 Route clock minute / hour edges', () {
    test('minute 59 ok; 60 invalid', () {
      expect(RouteClockTime.parse('07:59 AM'), isNotNull);
      expect(RouteClockTime.parse('07:60 AM'), isNull);
    });

    test('12-hour hour 1 and 12 ok; 0 and 13 invalid with AM/PM', () {
      expect(RouteClockTime.parse('01:00 AM'), isNotNull);
      expect(RouteClockTime.parse('12:00 PM'), isNotNull);
      expect(RouteClockTime.parse('00:00 AM'), isNull);
      expect(RouteClockTime.parse('13:00 PM'), isNull);
    });

    test('arrival equal departure is not "before"', () {
      expect(
        RouteClockTime.arrivalBeforeDeparture('07:30 AM', '07:30 AM'),
        isFalse,
      );
      expect(
        RouteClockTime.arrivalBeforeDeparture('07:30 AM', '07:29 AM'),
        isTrue,
      );
      expect(
        RouteClockTime.arrivalBeforeDeparture('07:30 AM', '07:31 AM'),
        isFalse,
      );
    });

    test('format pads single-digit hour/minute', () {
      expect(
        RouteClockTime.format(const TimeOfDay(hour: 7, minute: 5)),
        '07:05 AM',
      );
    });
  });

  group('BVT-09 GPS coordinate / freshness edges', () {
    test('0,0 and near-zero are invalid; tiny real coords valid', () {
      const zero = GpsLocationModel(
        tripId: 't',
        busId: 'b',
        driverId: 'd',
        latitude: 0,
        longitude: 0,
      );
      expect(zero.hasValidCoords, isFalse);

      const near = GpsLocationModel(
        tripId: 't',
        busId: 'b',
        driverId: 'd',
        latitude: 0.00005,
        longitude: 0.00005,
      );
      expect(near.hasValidCoords, isFalse);

      const ok = GpsLocationModel(
        tripId: 't',
        busId: 'b',
        driverId: 'd',
        latitude: 0.0002,
        longitude: 0,
      );
      expect(ok.hasValidCoords, isTrue);
    });

    test('isLive: under 2 minutes true; at/after 2 minutes false', () {
      GpsLocationModel gps(Duration ago) => GpsLocationModel(
            tripId: 't',
            busId: 'b',
            driverId: 'd',
            latitude: 25.1,
            longitude: 62.3,
            isActive: true,
            updatedAt: DateTime.now().toUtc().subtract(ago),
          );

      expect(gps(const Duration(minutes: 1, seconds: 50)).isLive, isTrue);
      expect(gps(const Duration(minutes: 2)).isLive, isFalse);
      expect(gps(const Duration(minutes: 3)).isLive, isFalse);
    });
  });

  group('BVT-10 Trip start assignment edges', () {
    test('empty / whitespace / Not Assigned rejected at the edge', () {
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: '',
          routeId: 'r1',
        ),
        throwsA(isA<TripStartException>()),
      );
      expect(
        () => TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: '   ',
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
          routeId: 'r1',
        ),
        returnsNormally,
      );
    });
  });

  group('BVT-11 Bus id soft-match edges', () {
    test('empty never matches; UOG-01 ≈ uog-001; UOG-01 ≠ UOG-02', () {
      expect(TripTrackingService.idsMatch('', 'UOG-01'), isFalse);
      expect(TripTrackingService.idsMatch('UOG-01', null), isFalse);
      expect(TripTrackingService.idsMatch('UOG-01', 'uog-001'), isTrue);
      expect(TripTrackingService.idsMatch('UOG-01', 'UOG-02'), isFalse);
      expect(TripTrackingService.idsMatch('uog0', 'uog00'), isTrue); // same numeric 0
      expect(TripTrackingService.idsMatch('uog0', 'uog1'), isFalse);
    });
  });

  group('BVT-12 Full name word-count edge', () {
    test('one word rejected; two accepted', () {
      expect(AppValidators.validateFullName('Ali'), isNotNull);
      expect(AppValidators.validateFullName('Ali Khan'), isNull);
    });
  });
}
