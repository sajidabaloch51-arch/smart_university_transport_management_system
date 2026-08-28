import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userRole;

  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;

  void setAuthenticated(bool value, {String? role}) {
    _isAuthenticated = value;
    _userRole = role;
    notifyListeners();
  }
}
