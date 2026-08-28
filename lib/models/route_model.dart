class RouteModel {
  final String id;
  final String universityId;
  final String routeName;
  final String routeNumber;
  final String startPoint;
  final String endPoint;
  final List<RouteStop> stops;
  final String totalDistance;
  final String estimatedDuration;
  final bool isActive;

  RouteModel({
    required this.id,
    required this.universityId,
    required this.routeName,
    required this.routeNumber,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    required this.totalDistance,
    required this.estimatedDuration,
    this.isActive = true,
  });

  factory RouteModel.fromMap(String id, Map<String, dynamic> map) {
    return RouteModel(
      id: id,
      universityId: map['universityId'] ?? '',
      routeName: map['routeName'] ?? '',
      routeNumber: map['routeNumber'] ?? '',
      startPoint: map['startPoint'] ?? '',
      endPoint: map['endPoint'] ?? '',
      stops: (map['stops'] as List? ?? [])
          .map((s) => RouteStop.fromMap(s as Map<String, dynamic>))
          .toList(),
      totalDistance: map['totalDistance'] ?? '',
      estimatedDuration: map['estimatedDuration'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'routeName': routeName,
      'routeNumber': routeNumber,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'stops': stops.map((s) => s.toMap()).toList(),
      'totalDistance': totalDistance,
      'estimatedDuration': estimatedDuration,
      'isActive': isActive,
    };
  }
}

class RouteStop {
  final String stopName;
  final double lat;
  final double lng;
  final int order;

  RouteStop({
    required this.stopName,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      stopName: map['stopName'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'lat': lat,
      'lng': lng,
      'order': order,
    };
  }
}
