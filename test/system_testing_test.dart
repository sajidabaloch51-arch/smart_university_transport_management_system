import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/constants/demo_credentials.dart';
import 'package:sutms/core/validators/app_validators.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/auth/driver_portal_entry_screen.dart';
import 'package:sutms/screens/auth/student_portal_entry_screen.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/auth_role_resolver.dart';
import 'package:sutms/services/password_hasher.dart';
import 'package:sutms/services/student_access_guard.dart';
import 'package:sutms/utils/firestore_query_exception.dart';
import 'package:sutms/widgets/async_state_view.dart';

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
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('DRIVER_DASHBOARD')),
          ),
        ),
        GoRoute(
          path: '/student-dashboard',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('STUDENT_DASHBOARD')),
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
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('LIVE_TRACKING')),
          ),
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
      expect(find.text('LIVE_TRACKING'), findsOneWidget);
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
