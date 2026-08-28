import 'package:go_router/go_router.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/login_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/driver/driver_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student-home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/driver-dashboard',
        builder: (context, state) => const DriverDashboard(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
}
