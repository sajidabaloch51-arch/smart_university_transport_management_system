import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remember Me credentials stored only in [FlutterSecureStorage]
/// (Android encrypted SharedPreferences / iOS Keychain).
/// Never writes the password to SharedPreferences or Firestore.
class RememberMeStore {
  RememberMeStore._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _emailKey(String role) => 'remembered_email_$role';
  static String _passwordKey(String role) => 'remembered_password_$role';

  static Future<({String email, String password})?> readCredentials(
    String role,
  ) async {
    final email = await _secure.read(key: _emailKey(role));
    final password = await _secure.read(key: _passwordKey(role));

    if (email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      return (email: email, password: password);
    }

    // Migrate legacy email-only remember (no password available).
    if (email != null && email.isNotEmpty) {
      return (email: email, password: '');
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString('remembered_email');
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(
        key: _emailKey(role),
        value: legacy.trim().toLowerCase(),
      );
      await prefs.remove('remembered_email');
      return (email: legacy, password: '');
    }
    return null;
  }

  static Future<void> writeCredentials(
    String role,
    String email,
    String password,
  ) async {
    await _secure.write(
      key: _emailKey(role),
      value: email.trim().toLowerCase(),
    );
    await _secure.write(key: _passwordKey(role), value: password);
  }

  static Future<void> clearCredentials(String role) async {
    await _secure.delete(key: _emailKey(role));
    await _secure.delete(key: _passwordKey(role));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
  }
}
