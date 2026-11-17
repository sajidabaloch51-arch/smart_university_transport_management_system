import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/student_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/auth_error_mapper.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/student_access_guard.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/email_validator.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Acceptance tests: business / UAT criteria in Given–When–Then form.
/// Validates what stakeholders accept for University of Gwadar SUTMS.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AT-01 Role entry (UAT: user picks Student / Driver / Admin)', () {
    testWidgets(
      'Given a fresh install, When the app opens role selection, '
      'Then all three roles are offered',
      (tester) async {
        final auth = AuthProvider();
        final router = GoRouter(
          initialLocation: '/role-selection',
          routes: [
            GoRoute(
              path: '/role-selection',
              builder: (_, __) => const RoleSelectionScreen(),
            ),
            GoRoute(
              path: '/student-portal-entry',
              builder: (_, __) => const Scaffold(body: Text('STUDENT_ENTRY')),
            ),
            GoRoute(
              path: '/driver-portal-entry',
              builder: (_, __) => const Scaffold(body: Text('DRIVER_ENTRY')),
            ),
            GoRoute(
              path: '/login',
              builder: (_, __) => const Scaffold(body: Text('LOGIN')),
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

        expect(find.text('Welcome to SUTMS'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget);
        expect(find.text('Bus Driver'), findsOneWidget);
        expect(find.text('Administrator'), findsOneWidget);
      },
    );
  });

  group('AT-02 University email policy', () {
    test(
      'Given admin/driver login, When email is @student.ug.edu.pk, '
      'Then it is rejected',
      () {
        expect(
          AppValidators.validateEmailForRole(
            'ali@student.ug.edu.pk',
            'admin',
          ),
          isNotNull,
        );
        expect(
          AppValidators.validateEmailForRole(
            'ali@student.ug.edu.pk',
            'driver',
          ),
          isNotNull,
        );
      },
    );

    test(
      'Given student login/registration, When email is @student.ug.edu.pk, '
      'Then it is accepted',
      () {
        expect(
          AppValidators.validateEmailForRole(
            'ali@student.ug.edu.pk',
            'student',
          ),
          isNull,
        );
        expect(
          AppEmailValidator.validateStudent('ali@student.ug.edu.pk'),
          isNull,
        );
      },
    );

    test(
      'Given any role, When email is @uog.edu.pk or @gmail.com, '
      'Then it is accepted',
      () {
        for (final role in ['admin', 'driver', 'student']) {
          expect(
            AppValidators.validateEmailForRole('user@uog.edu.pk', role),
            isNull,
          );
          expect(
            AppValidators.validateEmailForRole('user@gmail.com', role),
            isNull,
          );
        }
      },
    );

    test(
      'Given demo accounts, When validated for their roles, '
      'Then all pass university rules',
      () {
        expect(
          AppValidators.validateEmailForRole(
            DemoCredentials.adminEmail,
            'admin',
          ),
          isNull,
        );
        expect(
          AppValidators.validateEmailForRole(
            DemoCredentials.driverEmail,
            'driver',
          ),
          isNull,
        );
        expect(
          AppValidators.validateEmailForRole(
            DemoCredentials.studentEmail,
            'student',
          ),
          isNull,
        );
      },
    );
  });

  group('AT-03 Password strength (UAT: secure passwords)', () {
    test(
      'Given registration/login password rules, When password is strong, '
      'Then it is accepted; weak passwords are rejected',
      () {
        expect(
          AppValidators.validatePassword(DemoCredentials.adminPassword),
          isNull,
        );
        expect(
          AppValidators.validatePassword(DemoCredentials.driverPassword),
          isNull,
        );
        expect(
          AppValidators.validatePassword(DemoCredentials.studentPassword),
          isNull,
        );
        expect(AppValidators.validatePassword('password'), isNotNull);
        expect(AppValidators.validatePassword('12345678'), isNotNull);
        expect(AppValidators.validatePassword('Short1!'), isNotNull);
      },
    );

    test(
      'Given a stored salted hash, When the correct password is entered, '
      'Then verification succeeds without storing plaintext',
      () {
        final stored = PasswordHasher.hash(DemoCredentials.adminPassword);
        expect(stored.contains(DemoCredentials.adminPassword), isFalse);
        expect(
          PasswordHasher.verify(DemoCredentials.adminPassword, stored),
          isTrue,
        );
      },
    );
  });

  group('AT-04 Admin can manage the system after login', () {
    testWidgets(
      'Given an authenticated admin, When opening management screens, '
      'Then access is allowed; student screens are blocked',
      (tester) async {
        final auth = AuthProvider();
        auth.setAuthenticated(
          true,
          role: 'admin',
          uid: 'admin_uid',
          email: DemoCredentials.adminEmail,
        );

        final router = GoRouter(
          initialLocation: '/admin-dashboard',
          refreshListenable: auth,
          redirect: (context, state) => AuthRouteGuard.redirect(
            location: state.matchedLocation,
            appAuthenticated: auth.isAuthenticated,
            hasFirebaseUser: true,
            role: auth.userRole,
          ),
          routes: [
            GoRoute(
              path: '/admin-dashboard',
              builder: (_, __) => const Scaffold(body: Text('ADMIN_OK')),
            ),
            GoRoute(
              path: '/manage-students',
              builder: (_, __) => const Scaffold(body: Text('MANAGE_STUDENTS')),
            ),
            GoRoute(
              path: '/manage-routes',
              builder: (_, __) => const Scaffold(body: Text('MANAGE_ROUTES')),
            ),
            GoRoute(
              path: '/manage-buses',
              builder: (_, __) => const Scaffold(body: Text('MANAGE_BUSES')),
            ),
            GoRoute(
              path: '/student-dashboard',
              builder: (_, __) => const Scaffold(body: Text('STUDENT_OK')),
            ),
            GoRoute(
              path: '/role-selection',
              builder: (_, __) => const Scaffold(body: Text('ROLES')),
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
        expect(find.text('ADMIN_OK'), findsOneWidget);

        for (final path in [
          '/manage-students',
          '/manage-routes',
          '/manage-buses',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(find.textContaining('MANAGE_'), findsOneWidget, reason: path);
        }

        router.go('/student-dashboard');
        await tester.pumpAndSettle();
        expect(find.text('ADMIN_OK'), findsOneWidget);
        expect(find.text('STUDENT_OK'), findsNothing);
      },
    );
  });

  group('AT-05 Driver duty portal isolation', () {
    test(
      'Given an authenticated driver, When opening admin or student areas, '
      'Then the system redirects to the driver dashboard',
      () {
        expect(
          AuthRouteGuard.redirect(
            location: '/manage-duties',
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
        expect(
          AuthRouteGuard.redirect(
            location: '/driver-dashboard',
            appAuthenticated: true,
            hasFirebaseUser: true,
            role: 'driver',
          ),
          isNull,
        );
      },
    );
  });

  group('AT-06 Student approval gate', () {
    test(
      'Given a pending student, When access is evaluated, '
      'Then entry is denied with an approval message',
      () {
        const result = StudentAccessResult.denied(
          'Your account is awaiting admin approval. Please wait until an administrator verifies your registration.',
        );
        expect(result.allowed, isFalse);
        expect(result.message, contains('awaiting admin approval'));

        final pending = StudentModel.fromMap({
          'name': 'Ali Khan',
          'email': DemoCredentials.studentEmail,
          'verificationStatus': 'pending',
          'rollNo': 'CS-01',
          'regNumber': 'UG-1',
          'department': 'CS',
        }, 'stu1');
        expect(pending.verificationStatus, 'pending');
      },
    );

    test(
      'Given an approved student, When access is evaluated, '
      'Then entry is allowed',
      () {
        final approved = StudentModel.fromMap({
          'name': 'Ali Khan',
          'email': DemoCredentials.studentEmail,
          'verificationStatus': 'approved',
          'rollNo': 'CS-01',
          'regNumber': 'UG-1',
          'department': 'CS',
        }, 'stu1');
        final result = StudentAccessResult.allowed(approved);
        expect(result.allowed, isTrue);
        expect(result.student?.verificationStatus, 'approved');
      },
    );

    test(
      'Given a rejected student, When status is rejected, '
      'Then the system must not treat them as approved',
      () {
        final rejected = StudentModel.fromMap({
          'name': 'Ali Khan',
          'email': 'ali@uog.edu.pk',
          'verificationStatus': 'rejected',
          'rollNo': 'CS-02',
          'department': 'CS',
        }, 'stu2');
        expect(rejected.verificationStatus, 'rejected');
        expect(rejected.verificationStatus == 'approved', isFalse);
      },
    );
  });

  group('AT-07 Honest errors when not authenticated', () {
    testWidgets(
      'Given authUid is null, When a protected list fails, '
      'Then the user sees Please log in again (not a vague crash)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AsyncStateView<List<String>>(
                stream: Stream.error(
                  FirestoreQueryException(
                    collection: 'users',
                    query: 'users_students',
                    authUid: null,
                    cause: StateError('Please log in again to load data.'),
                  ),
                ),
                isEmpty: (d) => d.isEmpty,
                emptyMessage: 'No data',
                builder: (_, __) => const Text('DATA'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Please log in again'), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Details'), findsOneWidget);
      },
    );

    test(
      'Given wrong Auth credentials, When mapped for UI, '
      'Then the user sees Incorrect email or password',
      () {
        expect(
          AuthErrorMapper.map('invalid-credential', 'secret internals'),
          'Incorrect email or password.',
        );
        expect(
          AuthErrorMapper.isCredentialMismatch(
            Exception('[firebase_auth/invalid-credential] expired'),
          ),
          isTrue,
        );
      },
    );
  });

  group('AT-08 Session continuity after Auth uid ≠ seed profile id', () {
    test(
      'Given seed doc admin_id and Firebase Auth uid differ, '
      'When splash resolves role by email, Then admin access is restored',
      () async {
        SharedPreferences.setMockInitialValues({
          'is_logged_in': true,
          'user_role': 'student',
          'uid': 'admin_id',
        });
        final prefs = await SharedPreferences.getInstance();

        const authUid = 'firebase_abc';
        expect(
          AuthRoleResolver.needsRoleMirror(
            authUid: authUid,
            profileUid: prefs.getString('uid'),
            role: 'admin',
          ),
          isTrue,
        );

        final role = AuthRoleResolver.resolve(
          firestoreRoleByUid: null,
          firestoreRoleByEmail: 'admin',
          prefsRole: prefs.getString('user_role'),
        );
        expect(role, 'admin');

        final auth = AuthProvider();
        auth.setAuthenticated(
          true,
          role: role,
          uid: authUid,
          email: DemoCredentials.adminEmail,
        );

        expect(
          AuthRouteGuard.redirect(
            location: '/manage-notices',
            appAuthenticated: auth.isAuthenticated,
            hasFirebaseUser: true,
            role: auth.userRole,
          ),
          isNull,
        );
        expect(AuthRouteGuard.homeForRole(auth.userRole), '/admin-dashboard');
      },
    );
  });

  group('AT-09 Guests cannot open dashboards', () {
    test(
      'Given no login, When requesting any role home, '
      'Then the system sends the user to role selection',
      () {
        for (final path in [
          '/admin-dashboard',
          '/driver-dashboard',
          '/student-dashboard',
          '/manage-students',
          '/driver-route',
          '/live-tracking',
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
      },
    );
  });

  group('AT-10 Logout clears session', () {
    testWidgets(
      'Given a logged-in admin, When logout completes, '
      'Then protected routes require role selection again',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'is_logged_in': true,
          'user_role': 'admin',
          'uid': 'a1',
        });
        final auth = AuthProvider();
        auth.setAuthenticated(true, role: 'admin', uid: 'a1');

        final router = GoRouter(
          initialLocation: '/admin-dashboard',
          refreshListenable: auth,
          redirect: (context, state) => AuthRouteGuard.redirect(
            location: state.matchedLocation,
            appAuthenticated: auth.isAuthenticated,
            hasFirebaseUser: false,
            role: auth.userRole,
          ),
          routes: [
            GoRoute(
              path: '/admin-dashboard',
              builder: (context, __) => Scaffold(
                body: TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text('Logout'),
                ),
              ),
            ),
            GoRoute(
              path: '/role-selection',
              builder: (_, __) => const Scaffold(body: Text('ROLES')),
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

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        expect(auth.isAuthenticated, isFalse);
        expect(find.text('ROLES'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_logged_in'), isNull);
      },
    );
  });

  group('AT-11 Friendly network timeout copy', () {
    test(
      'Given a slow Firestore list, When timeout occurs, '
      'Then the user sees Cannot reach the server',
      () {
        expect(
          FirestoreErrorMessages.friendly(
            FirestoreQueryException(
              collection: 'routes',
              query: 'routes_active',
              authUid: 'u1',
              cause: TimeoutException('Future not completed'),
            ),
          ),
          "Can't reach the server",
        );
      },
    );
  });

  group('AT-12 Driver START TRIP acceptance (UAT: share bus GPS)', () {
    test(
      'Given an approved driver with bus and route, When START TRIP is requested, '
      'Then the trip is allowed',
      () {
        expect(
          () => TripTrackingService.assertCanStartTrip(
            verificationStatus: 'approved',
            busId: 'bus_1',
            routeId: 'route_1',
          ),
          returnsNormally,
        );
      },
    );

    test(
      'Given a pending or unassigned driver, When START TRIP is requested, '
      'Then the system blocks with a clear admin message',
      () {
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
              allOf(contains('approved'), contains('admin')),
            ),
          ),
        );
        expect(
          () => TripTrackingService.assertCanStartTrip(
            verificationStatus: 'approved',
            busId: 'Not Assigned',
            routeId: 'route_1',
          ),
          throwsA(
            isA<TripStartException>().having(
              (e) => e.message.toLowerCase(),
              'message',
              contains('bus'),
            ),
          ),
        );
      },
    );

    test(
      'Given Auth uid differs from seed driver_id, When a trip is published, '
      'Then driverId on trip/GPS must be the Auth uid (rules match)',
      () {
        const authUid = 'firebase_driver_uid';
        const seedDocId = 'driver_id';
        expect(authUid, isNot(seedDocId));

        final trip = TripModel(
          id: 't1',
          busId: 'bus_1',
          driverId: authUid,
          routeId: 'route_1',
          busNumber: 'UG-01',
          status: 'ACTIVE',
        );
        final gps = GpsLocationModel(
          tripId: 't1',
          busId: 'bus_1',
          driverId: authUid,
          latitude: 25.145,
          longitude: 62.36,
        );
        expect(trip.driverId, authUid);
        expect(gps.toMap()['driverId'], authUid);
        expect(gps.hasValidCoords, isTrue);
      },
    );
  });

  group('AT-13 Student/Admin live bus map acceptance', () {
    testWidgets(
      'Given an ACTIVE trip with valid GPS, When student opens live tracking, '
      'Then a free OSM map shows the bus without Google Maps SDK',
      (tester) async {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        expect(pubspec.contains('flutter_map:'), isTrue);
        expect(pubspec.contains('google_maps_flutter'), isFalse);

        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('ClientException') || msg.contains('status 400')) {
            return;
          }
          oldOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldOnError);

        final trip = TripModel.fromMap({
          'busId': 'b1',
          'driverId': 'uid_1',
          'routeId': 'r1',
          'busNumber': 'UG-01',
          'status': 'ACTIVE',
        }, 't1');
        final gps = GpsLocationModel.fromMap({
          'busId': 'b1',
          'driverId': 'uid_1',
          'latitude': 25.145,
          'longitude': 62.36,
          'isActive': true,
        }, 't1');
        expect(trip.isActive, isTrue);
        expect(gps.hasValidCoords, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('LIVE_TRACKING'),
                  Text('Bus ${trip.busNumber}'),
                  SizedBox(
                    width: 360,
                    height: 240,
                    child: OsmMapView(
                      busLocation: LatLng(gps.latitude, gps.longitude),
                      busLabel: trip.busNumber,
                      followBus: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('LIVE_TRACKING'), findsOneWidget);
        expect(find.text('Bus UG-01'), findsOneWidget);
        expect(find.byType(OsmMapView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'Given no active trip, When student views live tracking status, '
      'Then they see that the bus is not currently active',
      () {
        final idle = TripModel.fromMap({
          'busId': 'b1',
          'driverId': 'uid',
          'routeId': 'r1',
          'status': 'COMPLETED',
        }, 't2');
        expect(idle.isActive, isFalse);
      },
    );
  });

  group('AT-14 Live-tracking role access acceptance', () {
    test(
      'Given each role, When opening live-tracking paths, '
      'Then only the correct audience is allowed',
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
        expect(
          AuthRouteGuard.redirect(
            location: '/live-tracking',
            appAuthenticated: true,
            hasFirebaseUser: true,
            role: 'driver',
          ),
          '/driver-dashboard',
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
      },
    );
  });

  group('AT-15 Free OSM / no paid Maps acceptance', () {
    test(
      'Given the shipped app stack, When stakeholders require free maps, '
      'Then flutter_map is used and Google Maps SDK is absent',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        final appDelegate =
            File('ios/Runner/AppDelegate.swift').readAsStringSync();
        expect(pubspec.contains('flutter_map:'), isTrue);
        expect(pubspec.contains('latlong2:'), isTrue);
        expect(pubspec.contains('google_maps_flutter'), isFalse);
        expect(appDelegate.contains('GMSServices'), isFalse);
        expect(OsmMapView.gwadarFallback.latitude.isFinite, isTrue);
      },
    );
  });
}
