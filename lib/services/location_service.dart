import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        kIsWeb
            ? 'Browser location is off or blocked. Allow location for localhost/HTTPS.'
            : 'Location services are disabled. Turn on GPS and try again.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Allow location to share GPS.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable it in system settings.',
      );
    }

    return true;
  }

  /// Get a single current position
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Stream of location updates for live tracking.
  /// On Android, uses a visible foreground notification while trip is ACTIVE.
  Stream<Position> getPositionStream({
    int distanceFilterMeters = 8,
    bool foregroundNotification = false,
  }) {
    LocationSettings locationSettings;

    if (!kIsWeb && Platform.isAndroid && foregroundNotification) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        intervalDuration: const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'SUTMS trip active',
          notificationText: 'Sharing bus GPS with students and admin',
          notificationChannelName: 'SUTMS Trip Tracking',
          enableWakeLock: true,
        ),
      );
    } else if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: true,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
