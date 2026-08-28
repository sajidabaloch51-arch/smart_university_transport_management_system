import 'dart:math' show cos, sqrt, asin;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  /// Calculate straight-line distance between two coordinates in km (Haversine formula)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Estimate time in minutes based on distance and average speed (e.g., 30 km/h)
  int estimateTimeInMinutes(double distanceKm, {double averageSpeedKmh = 30.0}) {
    if (distanceKm <= 0) return 0;
    double timeHours = distanceKm / averageSpeedKmh;
    return (timeHours * 60).round();
  }

  /// Get ETA string
  String getETAString(LatLng start, LatLng end) {
    double distance = calculateDistance(start.latitude, start.longitude, end.latitude, end.longitude);
    int minutes = estimateTimeInMinutes(distance);
    
    if (minutes < 1) return "Arriving now";
    return "$minutes min away";
  }
}
