import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/driver_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/student_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/utils/firestore_parse.dart';
import 'package:sutms/utils/perf_log.dart';
import 'package:sutms/widgets/async_state_view.dart';

/// Performance tests: assert hot paths stay within budgets (CPU / UI frame).
/// Budgets are intentionally conservative for CI VMs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => PerfLog.resetForTest());

  group('PT-01 AuthRouteGuard throughput', () {
    test('10k redirect checks complete under 200ms', () {
      const paths = [
        '/manage-students',
        '/driver-dashboard',
        '/student-routes',
        '/login',
        '/role-selection',
        '/live-tracking',
        '/manage-buses',
      ];
      final roles = ['admin', 'driver', 'student', null];

      final ms = PerfLog.measureSync('guard_10k', () {
        var i = 0;
        for (var n = 0; n < 10000; n++) {
          AuthRouteGuard.redirect(
            location: paths[n % paths.length],
            appAuthenticated: n.isEven,
            hasFirebaseUser: n % 3 == 0,
            role: roles[n % roles.length],
          );
          i++;
        }
        expect(i, 10000);
      });

      expect(ms, lessThan(200), reason: 'guard took ${ms}ms');
    });
  });

  group('PT-02 AuthRoleResolver throughput', () {
    test('20k role resolves complete under 150ms', () {
      final ms = PerfLog.measureSync('role_20k', () {
        for (var n = 0; n < 20000; n++) {
          AuthRoleResolver.resolve(
            firestoreRoleByUid: n.isEven ? 'admin' : null,
            firestoreRoleByEmail: 'driver',
            prefsRole: 'student',
          );
          AuthRoleResolver.needsRoleMirror(
            authUid: 'auth_$n',
            profileUid: n.isEven ? 'seed_$n' : 'auth_$n',
            role: 'admin',
          );
        }
      });
      expect(ms, lessThan(150), reason: 'resolver took ${ms}ms');
    });
  });

  group('PT-03 Validators + email normalize', () {
    test('5k email/password validations under 200ms', () {
      final ms = PerfLog.measureSync('validators_5k', () {
        for (var n = 0; n < 5000; n++) {
          AppEmailValidator.normalize('  Ali$n@UOG.EDU.PK ');
          AppValidators.validateEmailForRole(
            DemoCredentials.adminEmail,
            'admin',
          );
          AppValidators.validateEmailForRole(
            'x$n@student.ug.edu.pk',
            'student',
          );
          AppValidators.validatePassword(DemoCredentials.adminPassword);
          AppValidators.validatePhone('03001234567');
        }
      });
      expect(ms, lessThan(200), reason: 'validators took ${ms}ms');
    });
  });

  group('PT-04 PasswordHasher', () {
    test('200 hashes with fixed salt under 300ms', () {
      // Fixed salt avoids Random.secure cost so we measure digest work.
      final ms = PerfLog.measureSync('hash_200', () {
        for (var n = 0; n < 200; n++) {
          final h = PasswordHasher.hash('Secret@$n', salt: 'perf_salt');
          expect(PasswordHasher.verify('Secret@$n', h), isTrue);
        }
      });
      expect(ms, lessThan(300), reason: 'hasher took ${ms}ms');
    });
  });

  group('PT-05 Model fromMap batch parse', () {
    test('1k students + 500 drivers + 500 routes under 250ms', () {
      final ms = PerfLog.measureSync('models_2k', () {
        for (var n = 0; n < 1000; n++) {
          StudentModel.fromMap({
            'name': 'Student $n',
            'email': 's$n@uog.edu.pk',
            'phone': '03001234567',
            'rollNo': 'R-$n',
            'regNumber': 'UG-$n',
            'department': 'CS',
            'verificationStatus': n.isEven ? 'approved' : 'pending',
            'termsAccepted': 1,
            'assignedRouteId': 'route_${n % 20}',
          }, 'stu_$n');
        }
        for (var n = 0; n < 500; n++) {
          DriverModel.fromMap({
            'name': 'Driver $n',
            'email': 'd$n@uog.edu.pk',
            'isOnDuty': n.isEven ? 'true' : false,
            'experienceYears': '$n',
            'licenseExpiryDate': '2026-06-01T00:00:00Z',
            'assignedRouteId': 'route_${n % 10}',
            'assignedBusId': 'bus_$n',
            'assignedBusNumber': 'UG-$n',
            'assignedRouteName': 'Loop $n',
          }, 'drv_$n');
        }
        for (var n = 0; n < 500; n++) {
          RouteModel.fromMap('r_$n', {
            'routeName': 'Route $n',
            'routeNumber': 'R$n',
            'startLocation': 'A$n',
            'endLocation': 'B$n',
            'departureTime': '07:30 AM',
            'arrivalTime': '08:15 AM',
            'estimatedTime': '45 min',
            'stops': [
              {'stopName': 'A$n', 'timeLabel': '07:30 AM'},
              'bad',
              {'stopName': 'B$n', 'timeLabel': '08:15 AM'},
            ],
            'viaStops': ['X', null, n],
            'isActive': n % 3 != 0,
          });
        }
      });
      expect(ms, lessThan(250), reason: 'model parse took ${ms}ms');
    });
  });

  group('PT-06 FirestoreParse helpers', () {
    test('20k asString/asInt/asBool/asDateTime under 250ms', () {
      final ms = PerfLog.measureSync('parse_20k', () {
        for (var n = 0; n < 20000; n++) {
          FirestoreParse.asString(n);
          FirestoreParse.asInt('$n');
          FirestoreParse.asBool(n.isEven);
          FirestoreParse.asDateTime(1700000000000 + n);
          FirestoreParse.asStringList([null, 'a', n]);
        }
      });
      // DateTime allocation dominates; keep headroom for slower CI hosts.
      expect(ms, lessThan(250), reason: 'parse helpers took ${ms}ms');
    });
  });

  group('PT-07 AuthErrorMapper', () {
    test('10k credential mismatch detections under 200ms', () {
      final wrapped = Exception(
        '[firebase_auth/invalid-credential] The supplied auth '
        'credential is incorrect, malformed or has expired.',
      );
      final ms = PerfLog.measureSync('auth_map_10k', () {
        for (var n = 0; n < 10000; n++) {
          AuthErrorMapper.isCredentialMismatch(wrapped);
          AuthErrorMapper.map('invalid-credential', null);
          AuthErrorMapper.isConfigurationError('CONFIGURATION_NOT_FOUND');
        }
      });
      expect(ms, lessThan(200), reason: 'auth mapper took ${ms}ms');
    });
  });

  group('PT-08 UI first paint budgets', () {
    testWidgets('RoleSelectionScreen pumps under 1500ms', (tester) async {
      final auth = AuthProvider();
      final router = GoRouter(
        initialLocation: '/role-selection',
        routes: [
          GoRoute(
            path: '/role-selection',
            builder: (_, __) => const RoleSelectionScreen(),
          ),
        ],
      );

      final ms = await PerfLog.measureAsync('ui_role_selection', () async {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: auth,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
      });

      expect(find.text('Welcome to SUTMS'), findsOneWidget);
      expect(ms, lessThan(1500), reason: 'role selection UI took ${ms}ms');
    });

    testWidgets('AsyncStateView data path paints under 800ms', (tester) async {
      final ms = await PerfLog.measureAsync('ui_async_data', () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AsyncStateView<List<String>>(
                stream: Stream.value(
                  List.generate(200, (i) => 'item_$i'),
                ),
                isEmpty: (d) => d.isEmpty,
                emptyMessage: 'empty',
                builder: (_, data) => ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (_, i) => Text(data[i]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      expect(find.text('item_0'), findsOneWidget);
      expect(ms, lessThan(800), reason: 'async list UI took ${ms}ms');
    });
  });

  group('PT-09 AuthProvider notify storm', () {
    test('1k setAuthenticated/cacheProfile cycles under 100ms', () {
      final auth = AuthProvider();
      var ticks = 0;
      auth.addListener(() => ticks++);

      final ms = PerfLog.measureSync('auth_provider_1k', () {
        for (var n = 0; n < 1000; n++) {
          auth.setAuthenticated(
            true,
            role: n.isEven ? 'admin' : 'student',
            uid: 'u$n',
            email: 'u$n@uog.edu.pk',
          );
          auth.cacheProfile(displayName: 'User $n', role: 'admin');
        }
      });

      expect(ticks, greaterThan(0));
      expect(ms, lessThan(100), reason: 'AuthProvider took ${ms}ms');
    });
  });

  group('PT-10 PerfLog API', () {
    test('start/elapsed/end lifecycle', () {
      PerfLog.start('demo');
      expect(PerfLog.elapsedMs('demo'), isNotNull);
      expect(PerfLog.elapsedMs('demo')! >= 0, isTrue);
      PerfLog.end('demo');
      expect(PerfLog.elapsedMs('demo'), isNull);
      // Double-end must not throw.
      PerfLog.end('demo');
    });
  });
}
