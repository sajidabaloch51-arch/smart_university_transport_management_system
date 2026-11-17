/// Pure routing policy used by [AppRouter] — extracted for white-box tests.
class AuthRouteGuard {
  AuthRouteGuard._();

  static const publicPaths = <String>{
    '/',
    '/onboarding',
    '/role-selection',
    '/student-portal-entry',
    '/driver-portal-entry',
    '/login',
    '/forgot-password',
    '/student-registration',
  };

  static bool isAdminPath(String loc) {
    return loc == '/admin-dashboard' ||
        loc == '/admin-profile' ||
        loc == '/student-verification' ||
        loc == '/verify-details' ||
        loc == '/manage-students' ||
        loc == '/student-details' ||
        loc == '/manage-drivers' ||
        loc == '/manage-routes' ||
        loc == '/manage-buses' ||
        loc == '/manage-schedules' ||
        loc == '/manage-notices' ||
        loc == '/manage-duties' ||
        loc == '/assign-duty' ||
        loc == '/view-feedback' ||
        loc == '/system-reports' ||
        loc == '/admin-live-tracking' ||
        loc.startsWith('/add-edit-');
  }

  static bool isDriverPath(String loc) {
    return loc == '/driver-dashboard' ||
        loc == '/driver-profile' ||
        loc == '/edit-driver-profile' ||
        loc == '/driver-notices' ||
        loc == '/driver-route';
  }

  static bool isStudentPath(String loc) {
    return loc == '/student-dashboard' ||
        loc == '/student-home' ||
        loc == '/student-routes' ||
        loc.startsWith('/route-detail') ||
        loc == '/live-tracking' ||
        loc == '/notices' ||
        loc == '/notice-detail' ||
        loc == '/feedback' ||
        loc == '/schedule' ||
        loc == '/personal-info';
  }

  static String homeForRole(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return '/admin-dashboard';
      case 'driver':
        return '/driver-dashboard';
      default:
        return '/student-dashboard';
    }
  }

  /// Returns a redirect location, or null to allow navigation.
  ///
  /// [appAuthenticated] = AuthProvider.isAuthenticated
  /// [hasFirebaseUser] = FirebaseAuth.currentUser != null
  static String? redirect({
    required String location,
    required bool appAuthenticated,
    required bool hasFirebaseUser,
    required String? role,
  }) {
    final loggedIn = appAuthenticated || hasFirebaseUser;
    final normalizedRole = (role ?? '').toLowerCase();

    if (publicPaths.contains(location)) {
      if (loggedIn &&
          appAuthenticated &&
          (location == '/onboarding' ||
              location == '/login' ||
              location == '/role-selection')) {
        return homeForRole(normalizedRole);
      }
      return null;
    }

    if (!loggedIn) {
      return '/role-selection';
    }

    if (normalizedRole.isNotEmpty) {
      if (isAdminPath(location) && normalizedRole != 'admin') {
        return homeForRole(normalizedRole);
      }
      if (isDriverPath(location) && normalizedRole != 'driver') {
        return homeForRole(normalizedRole);
      }
      if (isStudentPath(location) && normalizedRole != 'student') {
        return homeForRole(normalizedRole);
      }
    }

    return null;
  }
}
