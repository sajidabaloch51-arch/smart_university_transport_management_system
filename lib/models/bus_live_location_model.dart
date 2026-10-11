/// Live bus location payload stored in Firebase Realtime Database
/// at path: liveBusLocations/{driverId}
class BusLiveLocationModel {
  final String driverId;
  final String driverName;
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeName;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final bool isOnDuty;
  final int lastUpdatedMillis;

  const BusLiveLocationModel({
    required this.driverId,
    required this.driverName,
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.isOnDuty,
    required this.lastUpdatedMillis,
  });

  DateTime get lastUpdated =>
      DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);

  bool get isLive {
    if (!isOnDuty) return false;
    final age = DateTime.now().difference(lastUpdated);
    return age.inMinutes < 3;
  }

  factory BusLiveLocationModel.fromMap(
    String driverId,
    Map<dynamic, dynamic> map,
  ) {
    return BusLiveLocationModel(
      driverId: driverId,
      driverName: (map['driverName'] ?? '').toString(),
      busId: (map['busId'] ?? '').toString(),
      busNumber: (map['busNumber'] ?? '').toString(),
      routeId: (map['routeId'] ?? '').toString(),
      routeName: (map['routeName'] ?? '').toString(),
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      isOnDuty: map['isOnDuty'] == true,
      lastUpdatedMillis: (map['lastUpdated'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'busId': busId,
      'busNumber': busNumber,
      'routeId': routeId,
      'routeName': routeName,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'isOnDuty': isOnDuty,
      'lastUpdated': lastUpdatedMillis,
    };
  }

  BusLiveLocationModel copyWith({
    double? lat,
    double? lng,
    double? speed,
    double? heading,
    bool? isOnDuty,
    int? lastUpdatedMillis,
  }) {
    return BusLiveLocationModel(
      driverId: driverId,
      driverName: driverName,
      busId: busId,
      busNumber: busNumber,
      routeId: routeId,
      routeName: routeName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      lastUpdatedMillis: lastUpdatedMillis ?? this.lastUpdatedMillis,
    );
  }
}
