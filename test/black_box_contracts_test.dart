import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/constants/demo_credentials.dart';

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
}
