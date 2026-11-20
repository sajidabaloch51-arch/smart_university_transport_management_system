import '../utils/firestore_parse.dart';

class GpsLocationModel {
  final String tripId;
  final String busId;
  final String driverId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final DateTime? updatedAt;
  final bool isActive;

  const GpsLocationModel({
    required this.tripId,
    required this.busId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.speed = 0,
    this.heading = 0,
    this.updatedAt,
    this.isActive = true,
  });

  bool get hasValidCoords =>
      latitude.abs() > 0.0001 || longitude.abs() > 0.0001;

  /// Fresh if updated within the last 2 minutes.
  bool get isLive {
    if (!isActive || !hasValidCoords || updatedAt == null) return false;
    return DateTime.now().toUtc().difference(updatedAt!.toUtc()).inMinutes < 2;
  }

  factory GpsLocationModel.fromMap(Map<String, dynamic> map, String tripId) {
    return GpsLocationModel(
      tripId: FirestoreParse.asString(map['tripId'], tripId),
      busId: FirestoreParse.asString(map['busId']),
      driverId: FirestoreParse.asString(map['driverId']),
      latitude: (map['latitude'] as num?)?.toDouble() ??
          (map['lat'] as num?)?.toDouble() ??
          0,
      longitude: (map['longitude'] as num?)?.toDouble() ??
          (map['lng'] as num?)?.toDouble() ??
          0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0,
      updatedAt: FirestoreParse.asDateTime(map['updatedAt']),
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'busId': busId,
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'isActive': isActive,
    };
  }
}
