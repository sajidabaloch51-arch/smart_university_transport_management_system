import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../services/firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  
  AdminModel? _admin;
  bool _isLoading = false;

  AdminModel? get admin => _admin;
  bool get isLoading => _isLoading;

  Future<void> fetchAdminData(String uid) async {
    _isLoading = true;
    notifyListeners();
    
    // Using simple fetch logic as a placeholder
    _admin = AdminModel(
      uid: uid,
      name: 'System Admin',
      email: 'admin@uog.edu.pk',
      phone: '+92 300 0000000',
      role: 'admin',
      university: 'University of Gwadar',
      profilePhoto: '',
    );
    
    _isLoading = false;
    notifyListeners();
  }
}
