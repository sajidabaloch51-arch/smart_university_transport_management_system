import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Local password hashing when Firebase Auth Email/Password is not enabled yet.
/// Never stores plaintext. Prefer Firebase Auth once Console is configured.
class PasswordHasher {
  static String _randomSalt([int length = 16]) {
    final r = Random.secure();
    final bytes = List<int>.generate(length, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String password, {String? salt}) {
    final usedSalt = salt ?? _randomSalt();
    final digest = sha256.convert(utf8.encode('$usedSalt::$password'));
    return '$usedSalt:${digest.toString()}';
  }

  static bool verify(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = parts[1];
    final digest = sha256.convert(utf8.encode('$salt::$password'));
    return digest.toString() == expected;
  }
}
