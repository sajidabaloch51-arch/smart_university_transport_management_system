import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<RouteModel>> streamRoutes() {
    return _db.collection('routes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addRoute(RouteModel route) async {
    _isLoading = true;
    notifyListeners();
    await _db.collection('routes').doc(route.id).set(route.toMap());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRoute(String id) async {
    await _db.collection('routes').doc(id).delete();
  }
}
