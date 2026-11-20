import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';

/// Navigation tests: GoRouter + AuthRouteGuard role entry, RBAC redirects,
/// and live-tracking path access (no live Firebase required).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter _roleEntryRouter() {
    return GoRouter(
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
  }

  group('NT-01 Role-selection navigation', () {
    testWidgets('Student card opens student portal entry', (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: _roleEntryRouter()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_ENTRY'), findsOneWidget);
    });

    testWidgets('Bus Driver card opens driver portal entry', (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: _roleEntryRouter()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bus Driver'));
      await tester.pumpAndSettle();
      expect(find.text('DRIVER_ENTRY'), findsOneWidget);
    });

    testWidgets('Administrator card opens login', (tester) async {
      final auth = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: _roleEntryRouter()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
    });
  });

  group('NT-02 Unauthenticated redirects', () {
    test('protected paths send guests to role-selection', () {
      for (final path in [
        '/student-dashboard',
        '/driver-dashboard',
        '/admin-dashboard',
        '/live-tracking',
        '/admin-live-tracking',
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
  });

  group('NT-03 Role home destinations', () {
    test('homeForRole maps each role to its dashboard', () {
      expect(AuthRouteGuard.homeForRole('admin'), '/admin-dashboard');
      expect(AuthRouteGuard.homeForRole('driver'), '/driver-dashboard');
      expect(AuthRouteGuard.homeForRole('student'), '/student-dashboard');
      expect(AuthRouteGuard.homeForRole('ADMIN'), '/admin-dashboard');
      expect(AuthRouteGuard.homeForRole(null), '/student-dashboard');
    });

    test('logged-in users leave login / role-selection for home', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/login',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'driver',
        ),
        '/driver-dashboard',
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/role-selection',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        '/admin-dashboard',
      );
    });
  });

  group('NT-04 Cross-role path blocking', () {
    test('student cannot open admin or driver paths', () {
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
          location: '/driver-dashboard',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        '/student-dashboard',
      );
    });

    test('driver cannot open student live-tracking or admin live', () {
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
          role: 'driver',
        ),
        '/driver-dashboard',
      );
    });

    test('admin is not redirected away from admin live tracking', () {
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

  group('NT-05 Live-tracking widget navigation', () {
    testWidgets('student can stay on /live-tracking', (tester) async {
      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: 'student',
        uid: 'stu1',
        email: 's@uog.edu.pk',
      );
      final router = GoRouter(
        initialLocation: '/live-tracking',
        refreshListenable: auth,
        redirect: (context, state) => AuthRouteGuard.redirect(
          location: state.matchedLocation,
          appAuthenticated: auth.isAuthenticated,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        routes: [
          GoRoute(
            path: '/live-tracking',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_LIVE')),
          ),
          GoRoute(
            path: '/student-dashboard',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_HOME')),
          ),
          GoRoute(
            path: '/admin-live-tracking',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_LIVE')),
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
      expect(find.text('STUDENT_LIVE'), findsOneWidget);

      router.go('/admin-live-tracking');
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_HOME'), findsOneWidget);
    });

    testWidgets('admin can open /admin-live-tracking', (tester) async {
      final auth = AuthProvider();
      auth.setAuthenticated(
        true,
        role: 'admin',
        uid: 'adm1',
        email: 'admin@uog.edu.pk',
      );
      final router = GoRouter(
        initialLocation: '/admin-live-tracking',
        refreshListenable: auth,
        redirect: (context, state) => AuthRouteGuard.redirect(
          location: state.matchedLocation,
          appAuthenticated: auth.isAuthenticated,
          hasFirebaseUser: true,
          role: auth.userRole,
        ),
        routes: [
          GoRoute(
            path: '/admin-live-tracking',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_LIVE')),
          ),
          GoRoute(
            path: '/admin-dashboard',
            builder: (_, __) => const Scaffold(body: Text('ADMIN_HOME')),
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
      expect(find.text('ADMIN_LIVE'), findsOneWidget);
    });
  });

  group('NT-06 Path classifiers', () {
    test('live tracking paths classified for the correct role', () {
      expect(AuthRouteGuard.isStudentPath('/live-tracking'), isTrue);
      expect(AuthRouteGuard.isAdminPath('/live-tracking'), isFalse);
      expect(AuthRouteGuard.isAdminPath('/admin-live-tracking'), isTrue);
      expect(AuthRouteGuard.isStudentPath('/admin-live-tracking'), isFalse);
      expect(AuthRouteGuard.isDriverPath('/driver-dashboard'), isTrue);
      expect(AuthRouteGuard.isDriverPath('/live-tracking'), isFalse);
    });
  });
}
