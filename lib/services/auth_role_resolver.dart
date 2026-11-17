/// Pure role resolution used by Splash — white-box testable without Firebase.
class AuthRoleResolver {
  AuthRoleResolver._();

  static const allowed = {'admin', 'driver', 'student'};

  /// Prefer Firestore role, then prefs, then student.
  static String resolve({
    String? firestoreRoleByUid,
    String? firestoreRoleByEmail,
    String? prefsRole,
  }) {
    for (final raw in [firestoreRoleByUid, firestoreRoleByEmail, prefsRole]) {
      final role = (raw ?? '').trim().toLowerCase();
      if (allowed.contains(role)) return role;
    }
    return 'student';
  }

  /// True when seed profile doc id differs from Auth uid and needs a mirror.
  static bool needsRoleMirror({
    required String authUid,
    required String? profileUid,
    required String? role,
  }) {
    if (authUid.isEmpty) return false;
    if (profileUid == null || profileUid.isEmpty) return false;
    if (profileUid == authUid) return false;
    final r = (role ?? '').trim().toLowerCase();
    return allowed.contains(r);
  }
}
