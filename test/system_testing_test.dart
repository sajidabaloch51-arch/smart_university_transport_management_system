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
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/auth/driver_portal_entry_screen.dart';
import 'package:sutms/screens/auth/student_portal_entry_screen.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/student_access_guard.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// System tests: end-to-end journeys across real navigation screens + auth
/// policy + session prefs + list error UI (Firebase Auth/Firestore stubbed).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider auth;
  late GoRouter router;

  /// Minimal login that mirrors production validation + session write, without
  /// calling Firebase Auth / Firestore.
  Widget fakeLogin(String? roleExtra) {
    return _SystemLoginScreen(initialRole: roleExtra ?? 'student');
  }

  GoRouter buildSystemRouter(AuthProvider a) {
    return GoRouter(
      initialLocation: '/role-selection',
      refreshListenable: a,
      redirect: (context, state) => AuthRouteGuard.redirect(
        location: state.matchedLocation,
        appAuthenticated: a.isAuthenticated,
        hasFirebaseUser: false,
        role: a.userRole,
      ),
      routes: [
        GoRoute(
          path: '/role-selection',
          builder: (_, __) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/student-portal-entry',
          builder: (_, __) => const StudentPortalEntryScreen(),
        ),
        GoRoute(
          path: '/driver-portal-entry',
          builder: (_, __) => const DriverPortalEntryScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => fakeLogin(state.extra as String?),
        ),
        GoRoute(
          path: '/student-registration',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('STUDENT_REGISTRATION')),
          ),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, __) => Scaffold(
            body: Column(
              children: [
                const Text('ADMIN_DASHBOARD'),
                TextButton(
                  onPressed: () => context.go('/manage-students'),
                  child: const Text('Open Students'),
                ),
                TextButton(
                  onPressed: () => context.go('/admin-live-tracking'),
                  child: const Text('Open Admin Live Tracking'),
                ),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/manage-students',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('MANAGE_STUDENTS')),
          ),
        ),
        GoRoute(
          path: '/manage-routes',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('MANAGE_ROUTES')),
          ),
        ),
        GoRoute(
          path: '/driver-dashboard',
          builder: (context, __) => Scaffold(
            body: Column(
              children: [
                const Text('DRIVER_DASHBOARD'),
                TextButton(
                  onPressed: () => context.go('/duty'),
                  child: const Text('Open Duty'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/duty',
          builder: (_, __) => const _SystemDutyScreen(),
        ),
        GoRoute(
          path: '/student-dashboard',
          builder: (context, __) => Scaffold(
            body: Column(
              children: [
                const Text('STUDENT_DASHBOARD'),
                TextButton(
                  onPressed: () => context.go('/live-tracking'),
                  child: const Text('Open Live Tracking'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/student-routes',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('STUDENT_ROUTES')),
          ),
        ),
        GoRoute(
          path: '/live-tracking',
          builder: (_, __) =>
              const _SystemLiveTrackingScreen(roleLabel: 'STUDENT'),
        ),
        GoRoute(
          path: '/admin-live-tracking',
          builder: (_, __) =>
              const _SystemLiveTrackingScreen(roleLabel: 'ADMIN'),
        ),
      ],
    );
  }

  Widget systemApp() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = AuthProvider();
    router = buildSystemRouter(auth);
    _SystemDutyScreen.lastTrip = null;
    _SystemDutyScreen.lastGps = null;
  });

  group('ST-01 Cold start → role selection → portals', () {
    testWidgets('welcome screen offers three roles', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to SUTMS'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Bus Driver'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
    });

    testWidgets('Student → portal → registration path', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('Student Portal'), findsOneWidget);

      await tester.tap(find.text('Student Registration'));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_REGISTRATION'), findsOneWidget);
    });

    testWidgets('Student → portal → login form', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student Login'));
      await tester.pumpAndSettle();

      expect(find.textContaining('SYSTEM_LOGIN'), findsOneWidget);
      expect(find.byKey(const Key('sys_email')), findsOneWidget);
    });

    testWidgets('Administrator opens login directly', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();
      expect(find.textContaining('SYSTEM_LOGIN'), findsOneWidget);
      expect(find.byKey(const Key('sys_login_btn')), findsOneWidget);
    });
  });

  group('ST-02 Admin system journey', () {
    testWidgets('valid demo login → dashboard → manage students → logout',
        (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sys_email')),
        DemoCredentials.adminEmail,
      );
      await tester.enterText(
        find.byKey(const Key('sys_password')),
        DemoCredentials.adminPassword,
      );
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('ADMIN_DASHBOARD'), findsOneWidget);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.userRole, 'admin');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_logged_in'), isTrue);
      expect(prefs.getString('user_role'), 'admin');

      await tester.tap(find.text('Open Students'));
      await tester.pumpAndSettle();
      expect(find.text('MANAGE_STUDENTS'), findsOneWidget);

      // Deep-link attack: student area must bounce home.
      router.go('/student-dashboard');
      await tester.pumpAndSettle();
      expect(find.text('ADMIN_DASHBOARD'), findsOneWidget);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isFalse);
      expect(find.text('Welcome to SUTMS'), findsOneWidget);
    });

    testWidgets('rejects weak password on admin login', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sys_email')),
        DemoCredentials.adminEmail,
      );
      await tester.enterText(find.byKey(const Key('sys_password')), 'weak');
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('ADMIN_DASHBOARD'), findsNothing);
      expect(auth.isAuthenticated, isFalse);
    });
  });

  group('ST-03 Driver system journey', () {
    testWidgets('driver login reaches driver dashboard only', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bus Driver'));
      await tester.pumpAndSettle();
      expect(find.text('Driver Portal'), findsOneWidget);

      await tester.tap(find.text('Driver Login'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sys_email')),
        DemoCredentials.driverEmail,
      );
      await tester.enterText(
        find.byKey(const Key('sys_password')),
        DemoCredentials.driverPassword,
      );
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('DRIVER_DASHBOARD'), findsOneWidget);

      router.go('/manage-routes');
      await tester.pumpAndSettle();
      expect(find.text('DRIVER_DASHBOARD'), findsOneWidget);
      expect(find.text('MANAGE_ROUTES'), findsNothing);
    });
  });

  group('ST-04 Student system journey', () {
    testWidgets('approved student reaches dashboard and routes', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Student Login'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sys_email')),
        DemoCredentials.studentEmail,
      );
      await tester.enterText(
        find.byKey(const Key('sys_password')),
        DemoCredentials.studentPassword,
      );
      // Mark as approved for this system journey.
      await tester.tap(find.byKey(const Key('sys_approved_toggle')));
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('STUDENT_DASHBOARD'), findsOneWidget);

      router.go('/student-routes');
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_ROUTES'), findsOneWidget);

      router.go('/live-tracking');
      await tester.pumpAndSettle();
      expect(find.textContaining('STUDENT_LIVE'), findsOneWidget);
    });

    testWidgets('pending student is denied before dashboard', (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();

      router.push('/login', extra: 'student');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sys_email')),
        DemoCredentials.studentEmail,
      );
      await tester.enterText(
        find.byKey(const Key('sys_password')),
        DemoCredentials.studentPassword,
      );
      // Leave approved toggle off → pending gate.
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('STUDENT_DASHBOARD'), findsNothing);
      expect(find.textContaining('awaiting admin approval'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets('student-only email domain accepted on student portal',
        (tester) async {
      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();
      router.push('/login', extra: 'student');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sys_email')),
        'ali@student.ug.edu.pk',
      );
      await tester.enterText(
        find.byKey(const Key('sys_password')),
        'Student@1234',
      );
      await tester.tap(find.byKey(const Key('sys_approved_toggle')));
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();

      expect(find.text('STUDENT_DASHBOARD'), findsOneWidget);
    });
  });

  group('ST-05 System-wide unauthenticated data policy', () {
    testWidgets('list error UI shows login-again when authUid is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.error(
                FirestoreQueryException(
                  collection: 'buses',
                  query: 'admin_buses',
                  authUid: null,
                  cause: StateError('Please log in again to load data.'),
                ),
              ),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'No buses',
              builder: (_, __) => const Text('BUSES'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Please log in again'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    test('cold start without session cannot open any role home', () {
      for (final home in [
        '/admin-dashboard',
        '/driver-dashboard',
        '/student-dashboard',
      ]) {
        expect(
          AuthRouteGuard.redirect(
            location: home,
            appAuthenticated: false,
            hasFirebaseUser: false,
            role: null,
          ),
          '/role-selection',
        );
      }
    });
  });

  group('ST-06 Session restore system scenario', () {
    testWidgets('stale student prefs + admin Firestore role → admin home',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_logged_in': true,
        'user_role': 'student',
        'uid': 'admin_id',
      });
      final prefs = await SharedPreferences.getInstance();

      const authUid = 'restored_auth_uid';
      final role = AuthRoleResolver.resolve(
        firestoreRoleByUid: null,
        firestoreRoleByEmail: 'admin',
        prefsRole: prefs.getString('user_role'),
      );
      expect(role, 'admin');
      expect(
        AuthRoleResolver.needsRoleMirror(
          authUid: authUid,
          profileUid: 'admin_id',
          role: role,
        ),
        isTrue,
      );

      await prefs.setString('uid', authUid);
      await prefs.setString('user_role', role);
      auth.setAuthenticated(
        true,
        role: role,
        uid: authUid,
        email: DemoCredentials.adminEmail,
      );

      await tester.pumpWidget(systemApp());
      router.go('/admin-dashboard');
      await tester.pumpAndSettle();
      expect(find.text('ADMIN_DASHBOARD'), findsOneWidget);
    });
  });

  group('ST-07 Live bus tracking system journey', () {
    testWidgets(
      'driver login → START TRIP → student opens live map with bus GPS',
      (tester) async {
        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('ClientException') || msg.contains('status 400')) {
            return;
          }
          oldOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldOnError);

        await tester.pumpWidget(systemApp());
        await tester.pumpAndSettle();

        // Driver portal login
        await tester.tap(find.text('Bus Driver'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Driver Login'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('sys_email')),
          DemoCredentials.driverEmail,
        );
        await tester.enterText(
          find.byKey(const Key('sys_password')),
          DemoCredentials.driverPassword,
        );
        await tester.tap(find.byKey(const Key('sys_login_btn')));
        await tester.pumpAndSettle();
        expect(find.text('DRIVER_DASHBOARD'), findsOneWidget);

        await tester.tap(find.text('Open Duty'));
        await tester.pumpAndSettle();
        expect(find.text('DUTY_SCREEN'), findsOneWidget);
        expect(find.text('START TRIP'), findsOneWidget);

        await tester.tap(find.text('START TRIP'));
        await tester.pumpAndSettle();
        expect(find.text('TRIP ACTIVE'), findsOneWidget);
        expect(find.text('END TRIP'), findsOneWidget);
        expect(_SystemDutyScreen.lastTrip?.driverId, auth.uid);
        expect(_SystemDutyScreen.lastGps?.hasValidCoords, isTrue);

        // Driver must not open student live tracking
        router.go('/live-tracking');
        await tester.pumpAndSettle();
        expect(find.text('DRIVER_DASHBOARD'), findsOneWidget);

        // Switch to approved student and open live tracking with same trip GPS
        await auth.logout();
        await tester.pumpAndSettle();
        expect(find.text('Welcome to SUTMS'), findsOneWidget);

        await tester.tap(find.text('Student'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Student Login'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('sys_email')),
          DemoCredentials.studentEmail,
        );
        await tester.enterText(
          find.byKey(const Key('sys_password')),
          DemoCredentials.studentPassword,
        );
        await tester.tap(find.byKey(const Key('sys_approved_toggle')));
        await tester.tap(find.byKey(const Key('sys_login_btn')));
        await tester.pumpAndSettle();
        expect(find.text('STUDENT_DASHBOARD'), findsOneWidget);

        await tester.tap(find.text('Open Live Tracking'));
        await tester.pumpAndSettle();
        expect(find.textContaining('STUDENT_LIVE'), findsOneWidget);
        expect(find.textContaining('UG-01'), findsWidgets);
        expect(find.byType(OsmMapView), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('admin login → admin live tracking map', (tester) async {
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('ClientException') || msg.contains('status 400')) {
          return;
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      // Seed an active trip as if a driver already started one.
      _SystemDutyScreen.lastTrip = const TripModel(
        id: 't_admin',
        busId: 'bus_1',
        driverId: 'drv_uid',
        routeId: 'route_1',
        busNumber: 'UG-01',
        routeName: 'Campus Loop',
        driverName: 'Demo Driver',
        status: 'ACTIVE',
      );
      _SystemDutyScreen.lastGps = const GpsLocationModel(
        tripId: 't_admin',
        busId: 'bus_1',
        driverId: 'drv_uid',
        latitude: 25.145,
        longitude: 62.36,
        isActive: true,
      );

      await tester.pumpWidget(systemApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrator'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sys_email')),
        DemoCredentials.adminEmail,
      );
      await tester.enterText(
        find.byKey(const Key('sys_password')),
        DemoCredentials.adminPassword,
      );
      await tester.tap(find.byKey(const Key('sys_login_btn')));
      await tester.pumpAndSettle();
      expect(find.text('ADMIN_DASHBOARD'), findsOneWidget);

      await tester.tap(find.text('Open Admin Live Tracking'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ADMIN_LIVE'), findsOneWidget);
      expect(find.byType(OsmMapView), findsOneWidget);

      // Admin cannot open student-only live path
      router.go('/live-tracking');
      await tester.pumpAndSettle();
      expect(find.text('ADMIN_DASHBOARD'), findsOneWidget);
    });
  });
}

/// System-test duty stand-in: START/END TRIP without device GPS / Firestore.
class _SystemDutyScreen extends StatefulWidget {
  const _SystemDutyScreen();

  static TripModel? lastTrip;
  static GpsLocationModel? lastGps;

  @override
  State<_SystemDutyScreen> createState() => _SystemDutyScreenState();
}

class _SystemDutyScreenState extends State<_SystemDutyScreen> {
  bool _onDuty = false;
  String? _error;

  void _toggle() {
    final auth = context.read<AuthProvider>();
    setState(() => _error = null);
    if (!_onDuty) {
      try {
        TripTrackingService.assertCanStartTrip(
          verificationStatus: 'approved',
          busId: 'bus_1',
          routeId: 'route_1',
        );
      } on TripStartException catch (e) {
        setState(() => _error = e.message);
        return;
      }
      final trip = TripModel(
        id: 'sys_trip_1',
        busId: 'bus_1',
        driverId: auth.uid ?? 'missing',
        routeId: 'route_1',
        busNumber: 'UG-01',
        routeName: 'Campus Loop',
        driverName: 'Demo Driver',
        status: 'ACTIVE',
      );
      final gps = GpsLocationModel(
        tripId: trip.id,
        busId: trip.busId,
        driverId: trip.driverId,
        latitude: 25.145,
        longitude: 62.36,
        isActive: true,
      );
      _SystemDutyScreen.lastTrip = trip;
      _SystemDutyScreen.lastGps = gps;
      setState(() => _onDuty = true);
    } else {
      final prev = _SystemDutyScreen.lastTrip;
      _SystemDutyScreen.lastTrip = TripModel(
        id: prev?.id ?? 'sys_trip_1',
        busId: prev?.busId ?? 'bus_1',
        driverId: prev?.driverId ?? '',
        routeId: prev?.routeId ?? 'route_1',
        busNumber: prev?.busNumber ?? 'UG-01',
        routeName: prev?.routeName ?? '',
        driverName: prev?.driverName ?? '',
        status: 'COMPLETED',
      );
      final prevGps = _SystemDutyScreen.lastGps;
      _SystemDutyScreen.lastGps = GpsLocationModel(
        tripId: _SystemDutyScreen.lastTrip!.id,
        busId: _SystemDutyScreen.lastTrip!.busId,
        driverId: _SystemDutyScreen.lastTrip!.driverId,
        latitude: prevGps?.latitude ?? 0,
        longitude: prevGps?.longitude ?? 0,
        isActive: false,
      );
      setState(() => _onDuty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('DUTY_SCREEN'),
          Text(_onDuty ? 'TRIP ACTIVE' : 'TRIP OFFLINE'),
          if (_error != null) Text(_error!),
          FilledButton(
            onPressed: _toggle,
            child: Text(_onDuty ? 'END TRIP' : 'START TRIP'),
          ),
        ],
      ),
    );
  }
}

/// System-test live tracking stand-in using last published trip GPS.
class _SystemLiveTrackingScreen extends StatelessWidget {
  final String roleLabel;
  const _SystemLiveTrackingScreen({required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final trip = _SystemDutyScreen.lastTrip;
    final gps = _SystemDutyScreen.lastGps;
    final active = trip?.isActive == true && (gps?.hasValidCoords ?? false);

    return Scaffold(
      body: Column(
        children: [
          Text('${roleLabel}_LIVE'),
          Text(active ? 'Bus ${trip!.busNumber} live' : 'Bus is not currently active'),
          if (active)
            SizedBox(
              width: 360,
              height: 240,
              child: OsmMapView(
                busLocation: LatLng(gps!.latitude, gps.longitude),
                busLabel: trip!.busNumber,
                followBus: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// System-test login stand-in for production LoginScreen (no Firebase).
class _SystemLoginScreen extends StatefulWidget {
  final String initialRole;
  const _SystemLoginScreen({required this.initialRole});

  @override
  State<_SystemLoginScreen> createState() => _SystemLoginScreenState();
}

class _SystemLoginScreenState extends State<_SystemLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _approvedStudent = false;
  String? _gateMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _gateMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final portalRole = widget.initialRole;
    final email = _email.text.trim();
    final password = _password.text;

    // Simulate local hash check used when Auth is unavailable / seeded.
    final hash = PasswordHasher.hash(password);
    if (!PasswordHasher.verify(password, hash)) {
      setState(() => _gateMessage = 'Incorrect email or password.');
      return;
    }

    if (portalRole == 'student' && !_approvedStudent) {
      const denied = StudentAccessResult.denied(
        'Your account is awaiting admin approval. Please wait until an administrator verifies your registration.',
      );
      setState(() => _gateMessage = denied.message);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('uid', 'sys_$portalRole');
    await prefs.setString('user_role', portalRole);

    if (!mounted) return;
    context.read<AuthProvider>().setAuthenticated(
          true,
          role: portalRole,
          uid: 'sys_$portalRole',
          email: email,
        );
    context.go(AuthRouteGuard.homeForRole(portalRole));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SYSTEM_LOGIN (${widget.initialRole})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('portal=${widget.initialRole}'),
              TextFormField(
                key: const Key('sys_email'),
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    AppValidators.validateEmailForRole(v, widget.initialRole),
              ),
              TextFormField(
                key: const Key('sys_password'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: AppValidators.validatePassword,
              ),
              if (widget.initialRole == 'student')
                SwitchListTile(
                  key: const Key('sys_approved_toggle'),
                  title: const Text('Simulate approved student'),
                  value: _approvedStudent,
                  onChanged: (v) => setState(() => _approvedStudent = v),
                ),
              if (_gateMessage != null)
                Text(_gateMessage!, style: const TextStyle(color: Colors.orange)),
              FilledButton(
                key: const Key('sys_login_btn'),
                onPressed: _submit,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
