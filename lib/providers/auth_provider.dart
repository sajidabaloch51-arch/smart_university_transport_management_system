import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userRole;
  String? _uid;

  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;
  String? get uid => _uid;

  void setAuthenticated(bool value, {String? role, String? uid}) {
    _isAuthenticated = value;
    _userRole = role;
    _uid = uid;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isAuthenticated = false;
    _userRole = null;
    _uid = null;
    notifyListeners();
  }
}
