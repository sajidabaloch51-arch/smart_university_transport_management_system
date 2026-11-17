import '../utils/firestore_parse.dart';

class TripModel {
  final String id;
  final String busId;
  final String driverId;
  final String routeId;
  final String busNumber;
  final String routeName;
  final String driverName;
  final String status; // ACTIVE | COMPLETED
  final DateTime? startTime;
  final DateTime? endTime;
  final double? lastLat;
  final double? lastLng;
  final DateTime? updatedAt;

  const TripModel({
    required this.id,
    required this.busId,
    required this.driverId,
    required this.routeId,
    this.busNumber = '',
    this.routeName = '',
    this.driverName = '',
    this.status = 'ACTIVE',
    this.startTime,
    this.endTime,
    this.lastLat,
    this.lastLng,
    this.updatedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      busId: FirestoreParse.asString(map['busId']),
      driverId: FirestoreParse.asString(map['driverId']),
      routeId: FirestoreParse.asString(map['routeId']),
      busNumber: FirestoreParse.asString(map['busNumber']),
      routeName: FirestoreParse.asString(map['routeName']),
      driverName: FirestoreParse.asString(map['driverName']),
      status: FirestoreParse.asString(map['status'], 'ACTIVE').toUpperCase(),
      startTime: FirestoreParse.asDateTime(map['startTime']),
      endTime: FirestoreParse.asDateTime(map['endTime']),
      lastLat: (map['lastLat'] as num?)?.toDouble(),
      lastLng: (map['lastLng'] as num?)?.toDouble(),
      updatedAt: FirestoreParse.asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'driverId': driverId,
      'routeId': routeId,
      'busNumber': busNumber,
      'routeName': routeName,
      'driverName': driverName,
      'status': status,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (lastLat != null) 'lastLat': lastLat,
      if (lastLng != null) 'lastLng': lastLng,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}
