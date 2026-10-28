import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remember Me stores **email only** (never the password).
///
/// Email is kept in [FlutterSecureStorage]. Session flags (role / uid /
/// is_logged_in) stay in SharedPreferences — those are not credentials.
class RememberMeStore {
  RememberMeStore._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _emailKey(String role) => 'remembered_email_$role';

  static Future<String?> readEmail(String role) async {
    final secure = await _secure.read(key: _emailKey(role));
    if (secure != null && secure.isNotEmpty) return secure;

    // One-time migrate from legacy SharedPreferences (email only — never password).
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString('remembered_email');
    if (legacy != null && legacy.isNotEmpty) {
      await writeEmail(role, legacy);
      await prefs.remove('remembered_email');
      return legacy;
    }
    return null;
  }

  static Future<void> writeEmail(String role, String email) async {
    await _secure.write(key: _emailKey(role), value: email.trim().toLowerCase());
  }

  static Future<void> clearEmail(String role) async {
    await _secure.delete(key: _emailKey(role));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
  }
}
