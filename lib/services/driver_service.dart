import 'firestore_service.dart';
import '../models/driver_model.dart';

class DriverService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Fetch driver profile data
  Future<DriverModel?> getProfile(String uid) async {
    return await _firestoreService.getDriverData(uid);
  }

  /// Update driver's duty status in Firestore
  Future<void> updateDutyStatus(String uid, bool status) async {
    await _firestoreService.updateDriverStatus(uid, status);
  }

  /// Send FCM Notification to Admin when trip starts/ends (Placeholder)
  Future<void> notifyAdminStatus(String driverName, String status) async {
    // Logic for Firebase Cloud Messaging would go here
    print('Notifying Admin: Driver $driverName is now $status');
  }
}
