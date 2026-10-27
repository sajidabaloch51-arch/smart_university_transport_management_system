import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userRole;
  String? _uid;
  String? _displayName;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;
  String? get uid => _uid;
  String? get displayName => _displayName;
  String? get email => _email;

  void setAuthenticated(
    bool value, {
    String? role,
    String? uid,
    String? displayName,
    String? email,
  }) {
    _isAuthenticated = value;
    _userRole = role;
    _uid = uid;
    if (displayName != null) _displayName = displayName;
    if (email != null) _email = email;
    notifyListeners();
  }

  /// Cache profile fields so screens don't re-fetch users/{uid} for role/name.
  void cacheProfile({String? displayName, String? email, String? role}) {
    var changed = false;
    if (displayName != null && displayName != _displayName) {
      _displayName = displayName;
      changed = true;
    }
    if (email != null && email != _email) {
      _email = email;
      changed = true;
    }
    if (role != null && role != _userRole) {
      _userRole = role;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isAuthenticated = false;
    _userRole = null;
    _uid = null;
    _displayName = null;
    _email = null;
    notifyListeners();
  }
}
