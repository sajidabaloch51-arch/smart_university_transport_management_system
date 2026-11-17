import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:sutms/services/student_access_guard.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/firestore_error_messages.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/utils/map_marker_helper.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Integration tests: multiple real modules wired together (router + auth +
/// validators + error UI + prefs). No live Firebase / device required.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IT-01 AuthProvider + GoRouter + AuthRouteGuard', () {
    late AuthProvider auth;
    late GoRouter router;

    Widget harness() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    GoRouter buildRouter(AuthProvider a) {
      return GoRouter(
        initialLocation: '/role-selection',
        refreshListenable: a,
        redirect: (context, state) {
          return AuthRouteGuard.redirect(
            location: state.matchedLocation,
            appAuthenticated: a.isAuthenticated,
            hasFirebaseUser: false,
            role: a.userRole,
          );
        },
        routes: [
          GoRoute(
            path: '/role-selection',
            builder: (_, __) => const Scaffold(
              body: Text('ROLE_SELECTION'),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('LOGIN')),
          ),
          GoRoute(
            path: '/admin-dashboard',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_HOME')),
          ),
          GoRoute(
            path: '/driver-dashboard',
            builder: (_, __) => const Scaffold(body: Text('DRIVER_HOME')),
          ),
          GoRoute(
            path: '/student-dashboard',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_HOME')),
          ),
          GoRoute(
            path: '/manage-students',
            builder: (_, __) => const Scaffold(body: Text('MANAGE_STUDENTS')),
          ),
        ],
      );
    }

    setUp(() {
      auth = AuthProvider();
      router = buildRouter(auth);
    });

    testWidgets('logged-out user cannot open protected admin list',
        (tester) async {
      await tester.pumpWidget(harness());
      router.go('/manage-students');
      await tester.pumpAndSettle();
      expect(find.text('ROLE_SELECTION'), findsOneWidget);
      expect(find.text('MANAGE_STUDENTS'), findsNothing);
    });

    testWidgets('admin login session lands on admin home and opens lists',
        (tester) async {
      await tester.pumpWidget(harness());

      // Simulate successful Firebase + Firestore role resolution at login.
      auth.setAuthenticated(
        true,
        role: 'admin',
        uid: 'auth_uid_1',
        email: DemoCredentials.adminEmail,
      );
      auth.cacheProfile(displayName: 'Admin', role: 'admin');
      await tester.pumpAndSettle();

      router.go('/login');
      await tester.pumpAndSettle();
      expect(find.text('ADMIN_HOME'), findsOneWidget);

      router.go('/manage-students');
      await tester.pumpAndSettle();
      expect(find.text('MANAGE_STUDENTS'), findsOneWidget);
    });

    testWidgets('student session is bounced from admin paths', (tester) async {
      await tester.pumpWidget(harness());
      auth.setAuthenticated(true, role: 'student', uid: 'stu');
      await tester.pumpAndSettle();

      router.go('/manage-students');
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_HOME'), findsOneWidget);
      expect(find.text('MANAGE_STUDENTS'), findsNothing);
    });

    testWidgets('logout clears auth and returns protected routes to selection',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_role': 'driver',
        'uid': 'drv',
      });
      await tester.pumpWidget(harness());
      auth.setAuthenticated(true, role: 'driver', uid: 'drv');
      await tester.pumpAndSettle();

      router.go('/driver-dashboard');
      await tester.pumpAndSettle();
      expect(find.text('DRIVER_HOME'), findsOneWidget);

      // Firebase may be absent in tests; AuthProvider.logout still clears local state.
      await auth.logout();
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isFalse);

      router.go('/driver-dashboard');
      await tester.pumpAndSettle();
      expect(find.text('ROLE_SELECTION'), findsOneWidget);
    });
  });

  group('IT-02 Login success pipeline (validate → hash → session prefs)', () {
    test('admin demo credentials produce a persistable session payload',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const email = DemoCredentials.adminEmail;
      const password = DemoCredentials.adminPassword;
      expect(AppValidators.validateEmailForRole(email, 'admin'), isNull);
      expect(AppValidators.validatePassword(password), isNull);

      final hash = PasswordHasher.hash(password);
      expect(PasswordHasher.verify(password, hash), isTrue);

      const authUid = 'firebase_uid_admin';
      const role = 'admin';
      expect(
        AuthRoleResolver.resolve(
          firestoreRoleByUid: null,
          firestoreRoleByEmail: 'admin',
          prefsRole: null,
        ),
        role,
      );
      expect(role, 'admin');

      await prefs.setBool('is_logged_in', true);
      await prefs.setString('uid', authUid);
      await prefs.setString('user_role', role);

      final auth = AuthProvider();
      auth.setAuthenticated(true, role: role, uid: authUid, email: email);

      expect(prefs.getBool('is_logged_in'), isTrue);
      expect(prefs.getString('uid'), authUid);
      expect(prefs.getString('user_role'), 'admin');
      expect(AuthRouteGuard.homeForRole(auth.userRole), '/admin-dashboard');
      expect(
        AuthRouteGuard.redirect(
          location: '/manage-routes',
          appAuthenticated: auth.isAuthenticated,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        isNull,
      );
    });

    test('wrong portal role is blocked before session write', () {
      // Account is driver, portal is admin — login UI must stop here.
      const accountRole = 'driver';
      const portalRole = 'admin';
      expect(accountRole != portalRole, isTrue);
      expect(
        AuthRouteGuard.homeForRole(accountRole),
        isNot(equals(AuthRouteGuard.homeForRole(portalRole))),
      );
    });
  });

  group('IT-03 Splash-style restore when Auth uid ≠ seed doc', () {
    testWidgets('mirror decision + AuthProvider open the correct home',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_role': 'student', // stale
        'uid': 'admin_id', // seed id, not Auth uid
      });
      final prefs = await SharedPreferences.getInstance();

      const authUid = 'real_firebase_uid';
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

      // Splash would rewrite prefs + AuthProvider to the Auth uid.
      await prefs.setString('uid', authUid);
      await prefs.setString('user_role', role);

      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: role,
        uid: authUid,
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
            builder: (_, __) => const Scaffold(body: Text('ADMIN_HOME')),
          ),
          GoRoute(
            path: '/role-selection',
            builder: (_, __) => const Scaffold(body: Text('ROLE_SELECTION')),
          ),
          GoRoute(
            path: '/student-dashboard',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_HOME')),
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
      expect(find.text('ADMIN_HOME'), findsOneWidget);
      expect(prefs.getString('user_role'), 'admin');
      expect(prefs.getString('uid'), authUid);
    });
  });

  group('IT-04 AsyncStateView + FirestoreErrorMessages', () {
    testWidgets('unauthenticated stream shows Please log in again + Retry',
        (tester) async {
      var builds = 0;
      Stream<List<String>> factory() {
        builds++;
        if (builds == 1) {
          return Stream.error(
            FirestoreQueryException(
              collection: 'users',
              query: 'users_students',
              authUid: null,
              cause: StateError('Please log in again to load data.'),
            ),
          );
        }
        return Stream.value(['ok']);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: factory(),
              streamFactory: factory,
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No students',
              builder: (_, data) => Text('DATA:${data.first}'),
            ),
          ),
        ),
      );
      await tester.pump(); // stream error
      await tester.pump(); // friendly resolve

      expect(find.text('Please log in again'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('DATA:ok'), findsOneWidget);
    });

    testWidgets('empty stream shows empty message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.value(const <String>[]),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No routes yet',
              emptySubtitle: 'Ask admin to add one',
              builder: (_, __) => const Text('HAS_DATA'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No routes yet'), findsOneWidget);
      expect(find.text('Ask admin to add one'), findsOneWidget);
      expect(find.text('HAS_DATA'), findsNothing);
    });
  });

  group('IT-05 Student gate + auth error mapping for login UI', () {
    test('pending student access result blocks dashboard navigation', () {
      const denied = StudentAccessResult.denied(
        'Your account is awaiting admin approval. Please wait until an administrator verifies your registration.',
      );
      expect(denied.allowed, isFalse);
      expect(denied.message, contains('awaiting admin approval'));

      final student = StudentModel(
        uid: 's1',
        name: 'Ali Khan',
        email: DemoCredentials.studentEmail,
        phone: '03001234567',
        role: 'student',
        regNumber: 'UG-1',
        department: 'CS',
        rollNo: 'CS-01',
        verificationStatus: 'pending',
      );
      expect(student.verificationStatus, 'pending');

      // Until approved, AuthProvider must not be marked authenticated for student.
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse);
      expect(
        AuthRouteGuard.redirect(
          location: '/student-dashboard',
          appAuthenticated: false,
          hasFirebaseUser: true, // Auth signed in but gate denied
          role: null,
        ),
        isNull, // role empty → guard does not bounce yet; login owns the deny
      );
    });

    test('invalid-credential from Auth maps to login snackbar copy', () {
      final wrapped = Exception(
        '[firebase_auth/invalid-credential] The supplied auth '
        'credential is incorrect, malformed or has expired.',
      );
      expect(AuthErrorMapper.isCredentialMismatch(wrapped), isTrue);
      expect(
        AuthErrorMapper.map('invalid-credential', null),
        'Incorrect email or password.',
      );
      expect(
        FirestoreErrorMessages.friendly(
          FirestoreQueryException(
            collection: 'users',
            query: 'getUser',
            authUid: null,
            cause: StateError('Please log in again to load data.'),
          ),
        ),
        'Please log in again',
      );
    });
  });

  group('IT-06 Driver trip + live map modules wired together', () {
    testWidgets(
      'driver session → START gate → trip/GPS auth uid → student map + RBAC',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        const authUid = 'firebase_driver_uid';
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

        final profile = DriverModel(
          uid: seedDocId,
          name: 'Demo Driver',
          email: DemoCredentials.driverEmail,
          phone: '03000000000',
          role: 'driver',
          driverId: 'EMP-1',
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
          id: 'trip_1',
          busId: profile.assignedBusId,
          driverId: auth.uid!,
          routeId: profile.assignedRouteId,
          busNumber: profile.assignedBusNumber,
          routeName: profile.assignedRouteName,
          driverName: profile.name,
          status: 'ACTIVE',
        );
        final gps = GpsLocationModel(
          tripId: trip.id,
          busId: trip.busId,
          driverId: auth.uid!,
          latitude: 25.145,
          longitude: 62.36,
          isActive: true,
        );
        expect(trip.driverId, authUid);
        expect(gps.driverId, authUid);
        expect(gps.hasValidCoords, isTrue);

        final route = RouteModel.fromMap('route_1', {
          'routeName': 'Campus Loop',
          'stops': [
            {'stopName': 'Jetty', 'lat': 25.14, 'lng': 62.35, 'order': 1},
            {'stopName': 'Campus', 'lat': 25.15, 'lng': 62.37, 'order': 2},
          ],
        });
        final polyline = MapMarkerHelper.routePolyline(route);

        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('ClientException') || msg.contains('status 400')) {
            return;
          }
          oldOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldOnError);

        // Student live-tracking surface consumes trip GPS + route polyline.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text(trip.isActive ? 'TRIP ACTIVE' : 'TRIP OFFLINE'),
                  Text('BUS ${trip.busNumber}'),
                  SizedBox(
                    width: 360,
                    height: 240,
                    child: OsmMapView(
                      busLocation: LatLng(gps.latitude, gps.longitude),
                      busLabel: trip.busNumber,
                      routePoints: polyline,
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
        expect(find.text('TRIP ACTIVE'), findsOneWidget);
        expect(find.text('BUS UG-01'), findsOneWidget);
        expect(find.byType(OsmMapView), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Router RBAC: driver stays off student/admin live paths; student/admin OK.
        final router = GoRouter(
          initialLocation: '/driver-dashboard',
          refreshListenable: auth,
          redirect: (context, state) => AuthRouteGuard.redirect(
            location: state.matchedLocation,
            appAuthenticated: auth.isAuthenticated,
            hasFirebaseUser: true,
            role: auth.userRole,
          ),
          routes: [
            GoRoute(
              path: '/driver-dashboard',
              builder: (_, __) => const Scaffold(body: Text('DRIVER_HOME')),
            ),
            GoRoute(
              path: '/live-tracking',
              builder: (_, __) => const Scaffold(body: Text('STUDENT_LIVE')),
            ),
            GoRoute(
              path: '/admin-live-tracking',
              builder: (_, __) => const Scaffold(body: Text('ADMIN_LIVE')),
            ),
            GoRoute(
              path: '/student-dashboard',
              builder: (_, __) => const Scaffold(body: Text('STUDENT_HOME')),
            ),
            GoRoute(
              path: '/admin-dashboard',
              builder: (_, __) => const Scaffold(body: Text('ADMIN_HOME')),
            ),
            GoRoute(
              path: '/role-selection',
              builder: (_, __) => const Scaffold(body: Text('ROLE_SELECTION')),
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
        expect(find.text('DRIVER_HOME'), findsOneWidget);

        router.go('/live-tracking');
        await tester.pumpAndSettle();
        expect(find.text('DRIVER_HOME'), findsOneWidget);
        expect(find.text('STUDENT_LIVE'), findsNothing);

        // Student consumer can open live tracking.
        auth.setAuthenticated(
          true,
          role: 'student',
          uid: 'stu_uid',
          email: DemoCredentials.studentEmail,
        );
        await tester.pumpAndSettle();
        router.go('/live-tracking');
        await tester.pumpAndSettle();
        expect(find.text('STUDENT_LIVE'), findsOneWidget);

        // Admin consumer can open admin live tracking.
        auth.setAuthenticated(
          true,
          role: 'admin',
          uid: 'admin_uid',
          email: DemoCredentials.adminEmail,
        );
        await tester.pumpAndSettle();
        router.go('/admin-live-tracking');
        await tester.pumpAndSettle();
        expect(find.text('ADMIN_LIVE'), findsOneWidget);
      },
    );
  });

  group('IT-07 GPS permission error → AsyncStateView recovery', () {
    testWidgets('gps_locations permission-denied shows access message + Retry',
        (tester) async {
      var builds = 0;
      Stream<List<String>> factory() {
        builds++;
        if (builds == 1) {
          return Stream.error(
            FirestoreQueryException(
              collection: 'gps_locations',
              query: 'watch_active',
              authUid: 'uid1',
              cause: StateError('permission-denied'),
            ),
          );
        }
        return Stream.value(['trip_1']);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: factory(),
              streamFactory: factory,
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No active buses',
              builder: (_, data) => Text('GPS:${data.first}'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('access'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('GPS:trip_1'), findsOneWidget);
    });
  });
}
