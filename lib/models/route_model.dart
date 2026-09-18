class RouteModel {
  final String id;
  final String universityId;
  final String routeName;
  final String routeNumber;
  final String startLocation;
  final String endLocation;
  final List<String> viaStops;
  final List<RouteStop> stops; // Keep for coordinates
  final String distanceKm;
  final String estimatedTime;
  final bool isActive;

  RouteModel({
    required this.id,
    required this.universityId,
    required this.routeName,
    required this.routeNumber,
    required this.startLocation,
    required this.endLocation,
    required this.viaStops,
    required this.stops,
    required this.distanceKm,
    required this.estimatedTime,
    this.isActive = true,
  });

  factory RouteModel.fromMap(String id, Map<String, dynamic> map) {
    return RouteModel(
      id: id,
      universityId: map['universityId'] ?? '',
      routeName: map['routeName'] ?? '',
      routeNumber: map['routeNumber'] ?? '',
      startLocation: map['startLocation'] ?? map['startPoint'] ?? '',
      endLocation: map['endLocation'] ?? map['endPoint'] ?? '',
      viaStops: List<String>.from(map['viaStops'] ?? []),
      stops: (map['stops'] as List? ?? [])
          .map((s) => RouteStop.fromMap(s as Map<String, dynamic>))
          .toList(),
      distanceKm: map['distanceKm'] ?? map['totalDistance'] ?? '',
      estimatedTime: map['estimatedTime'] ?? map['estimatedDuration'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'routeName': routeName,
      'routeNumber': routeNumber,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'viaStops': viaStops,
      'stops': stops.map((s) => s.toMap()).toList(),
      'distanceKm': distanceKm,
      'estimatedTime': estimatedTime,
      'isActive': isActive,
    };
  }

  RouteModel copyWith({
    String? id,
    String? universityId,
    String? routeName,
    String? routeNumber,
    String? startLocation,
    String? endLocation,
    List<String>? viaStops,
    List<RouteStop>? stops,
    String? distanceKm,
    String? estimatedTime,
    bool? isActive,
  }) {
    return RouteModel(
      id: id ?? this.id,
      universityId: universityId ?? this.universityId,
      routeName: routeName ?? this.routeName,
      routeNumber: routeNumber ?? this.routeNumber,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      viaStops: viaStops ?? this.viaStops,
      stops: stops ?? this.stops,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isActive: isActive ?? this.isActive,
    );
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
