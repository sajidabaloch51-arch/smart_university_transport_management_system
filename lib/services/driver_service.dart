import 'firestore_service.dart';
import 'location_service.dart';
import '../models/driver_model.dart';

class DriverService {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  Future<void> startDuty(String driverId) async {
    bool hasPermission = await _locationService.checkPermissions();
    if (hasPermission) {
      await _firestoreService.updateDriverStatus(driverId, true);
    } else {
      throw Exception('Location permission denied');
    }
  }

  Future<void> endDuty(String driverId) async {
    await _firestoreService.updateDriverStatus(driverId, false);
    // Optionally update live location to indicate offline
    await _firestoreService.updateLiveLocation(driverId, {'isOnDuty': false});
  }

  Stream<DriverModel?> streamDriverData(String driverId) {
    // Note: FirestoreService should ideally have a stream for driver data too
    // For now we'll assume a one-time fetch or implement a stream in FirestoreService
    return Stream.fromFuture(_firestoreService.getDriverData(driverId));
  }
}
