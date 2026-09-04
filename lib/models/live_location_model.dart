import 'package:cloud_firestore/cloud_firestore.dart';

class LiveLocationModel {
  final String driverId;
  final double lat;
  final double lng;
  final String routeId;
  final String busId;
  final bool isOnDuty;
  final DateTime lastUpdated;
  final double speed;

  LiveLocationModel({
    required this.driverId,
    required this.lat,
    required this.lng,
    required this.routeId,
    required this.busId,
    required this.isOnDuty,
    required this.lastUpdated,
    required this.speed,
  });

  factory LiveLocationModel.fromMap(String driverId, Map<String, dynamic> map) {
    return LiveLocationModel(
      driverId: driverId,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      routeId: map['routeId'] ?? '',
      busId: map['busId'] ?? '',
      isOnDuty: map['isOnDuty'] ?? false,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'routeId': routeId,
      'busId': busId,
      'isOnDuty': isOnDuty,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'speed': speed,
    };
  }
}
