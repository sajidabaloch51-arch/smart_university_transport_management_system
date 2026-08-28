import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../models/notice_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER OPERATIONS ---
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // --- ROUTE OPERATIONS ---
  Stream<List<RouteModel>> getRoutes(String universityId) {
    return _db
        .collection('routes')
        .where('universityId', isEqualTo: universityId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addRoute(RouteModel route) async {
    await _db.collection('routes').add(route.toMap());
  }

  // --- NOTICE OPERATIONS ---
  Stream<List<NoticeModel>> getNotices(String universityId) {
    return _db
        .collection('notices')
        .where('universityId', isEqualTo: universityId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoticeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addNotice(NoticeModel notice) async {
    await _db.collection('notices').add(notice.toMap());
  }

  // --- LIVE LOCATION ---
  Stream<DocumentSnapshot> getDriverLocation(String driverId) {
    return _db.collection('liveLocations').doc(driverId).snapshots();
  }

  Future<void> updateLiveLocation(String driverId, Map<String, dynamic> data) async {
    await _db.collection('liveLocations').doc(driverId).set(data, SetOptions(merge: true));
  }
}
