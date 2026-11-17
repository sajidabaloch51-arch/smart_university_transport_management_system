import 'dart:math' show asin, cos, sqrt;

import 'package:latlong2/latlong.dart';

class MapsService {
  /// Straight-line distance between two coordinates in km (Haversine).
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Estimate time in minutes based on distance and average speed (e.g. 30 km/h).
  int estimateTimeInMinutes(double distanceKm, {double averageSpeedKmh = 30.0}) {
    if (distanceKm <= 0) return 0;
    final timeHours = distanceKm / averageSpeedKmh;
    return (timeHours * 60).round();
  }

  /// Get ETA string between two LatLng points.
  String getETAString(LatLng start, LatLng end) {
    final distance = calculateDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    final minutes = estimateTimeInMinutes(distance);

    if (minutes < 1) return 'Arriving now';
    return '$minutes min away';
  }
}
