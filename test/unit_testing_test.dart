import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/bus_model.dart';
import 'package:sutms/models/notice_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/schedule_model.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/utils/firestore_parse.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/utils/karachi_time.dart';
import 'package:sutms/utils/phone_launcher.dart';

/// Classic unit tests: one function / class at a time, no Firebase I/O.
void main() {
  group('UT-01 AppValidators.password', () {
    test('accepts strong password', () {
      expect(AppValidators.validatePassword('Admin@1234'), isNull);
    });

    test('rejects empty, short, and incomplete strength', () {
      expect(AppValidators.validatePassword(null), isNotNull);
      expect(AppValidators.validatePassword(''), isNotNull);
      expect(AppValidators.validatePassword('Short1!'), isNotNull);
      expect(AppValidators.validatePassword('alllower1!'), isNotNull);
      expect(AppValidators.validatePassword('ALLUPPER1!'), isNotNull);
      expect(AppValidators.validatePassword('NoDigits!!'), isNotNull);
      expect(AppValidators.validatePassword('NoSpecial1'), isNotNull);
    });

    test('confirm password must match', () {
      expect(
        AppValidators.validateConfirmPassword('Admin@1234', 'Admin@1234'),
        isNull,
      );
      expect(
        AppValidators.validateConfirmPassword('Admin@1234', 'Other@1234'),
        isNotNull,
      );
    });
  });

  group('UT-02 AppValidators identity fields', () {
    test('full name needs two words', () {
      expect(AppValidators.validateFullName('Ali'), isNotNull);
      expect(AppValidators.validateFullName('Ali Khan'), isNull);
    });

    test('phone accepts PK mobile formats', () {
      expect(AppValidators.validatePhone('03001234567'), isNull);
      expect(AppValidators.validatePhone('+923001234567'), isNull);
      expect(AppValidators.validatePhone('0300-1234567'), isNull);
      expect(AppValidators.validatePhone('12345'), isNotNull);
    });

    test('CNIC 13 digits with optional dashes', () {
      expect(AppValidators.validateCNIC('12345-1234567-1'), isNull);
      expect(AppValidators.validateCNIC('1234512345671'), isNull);
      expect(AppValidators.validateCNIC('123'), isNotNull);
    });

    test('employee id UOG-EMP-###', () {
      expect(AppValidators.validateEmployeeId('UOG-EMP-001'), isNull);
      expect(AppValidators.validateEmployeeId('EMP-001'), isNotNull);
    });

    test('Balochistan license optional but format-checked when set', () {
      expect(AppValidators.validateBalochistanLicense(null), isNull);
      expect(AppValidators.validateBalochistanLicense(''), isNull);
      expect(AppValidators.validateBalochistanLicense('GAW-123456'), isNull);
      expect(AppValidators.validateBalochistanLicense('XYZ-99'), isNotNull);
    });

    test('roll / reg / experience bounds', () {
      expect(AppValidators.validateRollNo('CS-01'), isNull);
      expect(AppValidators.validateRollNo('A'), isNotNull);
      expect(AppValidators.validateRegNo('19-UOG-123'), isNull);
      expect(AppValidators.validateExperienceYears('5'), isNull);
      expect(AppValidators.validateExperienceYears('51'), isNotNull);
      expect(AppValidators.validateExperienceYears('x'), isNotNull);
    });
  });

  group('UT-03 AppEmailValidator', () {
    test('rejects empty, bad local, unknown domain', () {
      expect(AppEmailValidator.validate(null), isNotNull);
      expect(AppEmailValidator.validate(''), isNotNull);
      expect(AppEmailValidator.validate('a@b@c.com'), isNotNull);
      expect(AppEmailValidator.validate('.ali@uog.edu.pk'), isNotNull);
      expect(AppEmailValidator.validate('ali..khan@uog.edu.pk'), isNotNull);
      expect(AppEmailValidator.validate('ali@yahoo.com'), isNotNull);
    });

    test('student domain only on student validators', () {
      expect(
        AppEmailValidator.validateStudent('x@student.ug.edu.pk'),
        isNull,
      );
      expect(AppEmailValidator.validate('x@student.ug.edu.pk'), isNotNull);
      expect(AppEmailValidator.isAllowedForStudent('x@gmail.com'), isTrue);
      expect(AppEmailValidator.isAllowed('x@student.ug.edu.pk'), isFalse);
    });
  });

  group('UT-04 PasswordHasher', () {
    test('deterministic with fixed salt', () {
      final a = PasswordHasher.hash('Secret@1', salt: 'abc');
      final b = PasswordHasher.hash('Secret@1', salt: 'abc');
      expect(a, b);
      expect(a.split(':').length, 2);
    });

    test('empty and colon-only stored fail verify', () {
      expect(PasswordHasher.verify('x', ''), isFalse);
      expect(PasswordHasher.verify('x', ':'), isFalse);
      expect(PasswordHasher.verify('x', 'salt:only:extra'), isFalse);
    });
  });

  group('UT-05 AuthErrorMapper', () {
    test('maps network and rate-limit codes', () {
      expect(
        AuthErrorMapper.map('network-request-failed', null),
        contains('Network error'),
      );
      expect(
        AuthErrorMapper.map('too-many-requests', null),
        contains('Too many attempts'),
      );
      expect(
        AuthErrorMapper.map('weak-password', null),
        contains('too weak'),
      );
    });

    test('isEmailInUse / isUserMissing helpers', () {
      expect(
        AuthErrorMapper.isEmailInUse(
          Exception('[firebase_auth/email-already-in-use]'),
        ),
        isTrue,
      );
      expect(
        AuthErrorMapper.isUserMissing(
          Exception('[firebase_auth/user-not-found]'),
        ),
        isTrue,
      );
    });
  });

  group('UT-06 AuthRouteGuard path classifiers', () {
    test('isAdminPath / isDriverPath / isStudentPath', () {
      expect(AuthRouteGuard.isAdminPath('/manage-buses'), isTrue);
      expect(AuthRouteGuard.isAdminPath('/add-edit-route'), isTrue);
      expect(AuthRouteGuard.isAdminPath('/login'), isFalse);
      expect(AuthRouteGuard.isDriverPath('/driver-notices'), isTrue);
      expect(AuthRouteGuard.isStudentPath('/live-tracking'), isTrue);
      expect(AuthRouteGuard.isStudentPath('/route-detail/1'), isTrue);
    });

    test('homeForRole case-insensitive', () {
      expect(AuthRouteGuard.homeForRole('Driver'), '/driver-dashboard');
      expect(AuthRouteGuard.homeForRole(''), '/student-dashboard');
    });
  });

  group('UT-07 AuthRoleResolver', () {
    test('ignores unknown roles in the chain', () {
      expect(
        AuthRoleResolver.resolve(
          firestoreRoleByUid: 'superuser',
          firestoreRoleByEmail: 'ADMIN',
          prefsRole: 'driver',
        ),
        'admin',
      );
    });

    test('needsRoleMirror rejects empty auth uid', () {
      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: '',
          profileUid: 'admin_id',
          role: 'admin',
        ),
        isFalse,
      );
    });
  });

  group('UT-08 KarachiTime', () {
    test('dateString formats yyyy-MM-dd in UTC+5', () {
      // 2024-01-01 22:00 UTC → 2024-01-02 03:00 Karachi
      final utc = DateTime.utc(2024, 1, 1, 22, 0);
      expect(KarachiTime.dateString(utc), '2024-01-02');
    });

    test('combineToUtc subtracts +5 offset', () {
      final day = DateTime.utc(2024, 6, 15);
      final utc = KarachiTime.combineToUtc(day, 9, 30);
      expect(utc.isUtc, isTrue);
      expect(utc.hour, 4); // 09:30 PKT = 04:30 UTC
      expect(utc.minute, 30);
    });

    test('formatTime 12-hour with AM/PM', () {
      expect(
        KarachiTime.formatTime(DateTime.utc(2024, 1, 1, 4, 5)), // 09:05 PKT
        '9:05 AM',
      );
      expect(
        KarachiTime.formatTime(DateTime.utc(2024, 1, 1, 12, 0)), // 17:00 PKT
        '5:00 PM',
      );
    });

    test('formatDateTime includes month label', () {
      final s = KarachiTime.formatDateTime(DateTime.utc(2026, 10, 27, 16, 45));
      expect(s, contains('Oct'));
      expect(s, contains('2026'));
      expect(s, contains('PM'));
    });
  });

  group('UT-09 FirestoreParse', () {
    test('asDateTimeOrNow falls back', () {
      final nowish = FirestoreParse.asDateTimeOrNow(null);
      expect(
        nowish.difference(DateTime.now()).inSeconds.abs() < 5,
        isTrue,
      );
    });

    test('asBool fallback for junk', () {
      expect(FirestoreParse.asBool('maybe', fallback: true), isTrue);
      expect(FirestoreParse.asBool('no'), isFalse);
    });

    test('asStringList fallback when not a list', () {
      expect(
        FirestoreParse.asStringList('x', fallback: const ['a']),
        ['a'],
      );
    });
  });

  group('UT-10 FirestoreQueryException', () {
    test('toString and firebaseException getter', () {
      final err = FirestoreQueryException(
        collection: 'buses',
        query: 'all',
        authUid: 'u1',
        cause: const FormatException('bad'),
      );
      expect(err.toString(), contains('collection=buses'));
      expect(err.firebaseException, isNull);
      expect(err.isUnauthenticated, isFalse);
    });

    test('empty authUid treated as unauthenticated when cause is not auth', () {
      final err = FirestoreQueryException(
        collection: 'x',
        query: 'y',
        authUid: '',
        cause: Exception('other'),
      );
      expect(err.isUnauthenticated, isTrue);
    });
  });

  group('UT-11 PhoneLauncher.sanitize', () {
    test('keeps digits and leading plus', () {
      expect(PhoneLauncher.sanitize(' 0300-123-4567 '), '03001234567');
      expect(PhoneLauncher.sanitize('+92 300 1234567'), '+923001234567');
      expect(PhoneLauncher.sanitize(''), '');
      expect(PhoneLauncher.sanitize('abc'), '');
    });
  });

  group('UT-12 RouteModel helpers', () {
    test('looksLikeDuration detects duration strings', () {
      expect(RouteModel.looksLikeDuration('45 min'), isTrue);
      expect(RouteModel.looksLikeDuration('1 hour'), isTrue);
      expect(RouteModel.looksLikeDuration('07:30 AM'), isFalse);
      expect(RouteModel.looksLikeDuration(''), isFalse);
    });

    test('display helpers when driver missing', () {
      final r = RouteModel.fromMap('id', {
        'routeName': 'Loop',
        'routeNumber': 'R1',
      });
      expect(r.hasAssignedDriver, isFalse);
      expect(r.displayDriverName, 'Not Assigned');
      expect(r.displayBusCode, 'R1');
    });
  });

  group('UT-13 Model unit parse', () {
    test('NoticeModel priority → type and visibility', () {
      final urgent = NoticeModel.fromMap({
        'title': 'T',
        'message': 'M',
        'priority': 'urgent',
        'isActive': true,
        'expiresAt': DateTime.now().toUtc().add(const Duration(days: 1)),
      }, 'n1');
      expect(urgent.type, NoticeType.emergency);
      expect(urgent.isVisibleNow, isTrue);

      final expired = NoticeModel.fromMap({
        'title': 'T',
        'description': 'legacy body',
        'priority': 'normal',
        'expiresAt': DateTime.now().toUtc().subtract(const Duration(days: 1)),
      }, 'n2');
      expect(expired.message, 'legacy body');
      expect(expired.isExpired, isTrue);
      expect(expired.isVisibleNow, isFalse);
    });

    test('ScheduleModel tolerates busNumber alias and bad days', () {
      final s = ScheduleModel.fromMap({
        'busNumber': 'UG-9',
        'operationalDays': null,
        'shift': null,
      }, 'sch1');
      expect(s.id, 'sch1');
      expect(s.vehicleNo, 'UG-9');
      expect(s.shift, 'Morning');
      expect(s.operationalDays, isNotEmpty);
    });

    test('BusModel toMap omits Not Assigned junk', () {
      final b = BusModel(
        id: 'b1',
        busNumber: 'UG-01',
        assignedDriverId: 'Not Assigned',
        assignedRouteName: '  ',
        capacity: 40,
        isActive: true,
      );
      final map = b.toMap();
      expect(map.containsKey('assignedDriverId'), isFalse);
      expect(map.containsKey('assignedRouteName'), isFalse);
      expect(map['capacity'], 40);
      expect(map['busNumber'], 'UG-01');
    });
  });
}
