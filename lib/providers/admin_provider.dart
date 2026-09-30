import 'package:flutter/material.dart';
import '../models/admin_model.dart';

class AdminProvider extends ChangeNotifier {
  AdminModel? _admin;
  bool _isLoading = false;

  AdminModel? get admin => _admin;
  bool get isLoading => _isLoading;

  // Local cache for demo purposes
  final Map<String, AdminModel> _localAdmins = {};

  Future<void> fetchAdminData(String uid) async {
    if (_localAdmins.containsKey(uid)) {
      _admin = _localAdmins[uid];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    
    // Default mock admin if not in cache
    _admin = AdminModel(
      uid: uid,
      name: 'System Admin',
      email: 'admin@uog.edu.pk',
      phone: '+92 300 0000000',
      role: 'admin',
      university: 'University of Gwadar',
      profilePhoto: '',
      employeeId: 'EMP-001',
      designation: 'Super Admin',
      officeLocation: 'Main Admin Block',
    );
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAdmin(AdminModel admin) async {
    _isLoading = true;
    notifyListeners();

    try {
      _localAdmins[admin.uid] = admin;
      _admin = admin;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
