class RouteModel {
  final String id;
  final String universityId;
  final String routeName;
  final String routeNumber;
  final String startLocation;
  final String endLocation;
  final List<String> viaStops;
  final List<RouteStop> stops;
  final String distanceKm;
  final String estimatedTime;
  /// Clock time at first stop, e.g. "07:30 AM" (not duration).
  final String departureTime;
  /// Clock time at last stop, e.g. "08:15 AM".
  final String arrivalTime;
  final bool isActive;

  /// Source of truth for who drives this route (Firestore users doc id).
  final String? driverId;
  final String driverName;
  final String driverPhone;
  /// Linked bus document id (preferred over [busNo] alone).
  final String busId;
  final String busNo;

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
    this.departureTime = '',
    this.arrivalTime = '',
    this.isActive = true,
    this.driverId,
    this.driverName = '',
    this.driverPhone = '',
    this.busId = '',
    this.busNo = '',
  });

  bool get hasAssignedDriver =>
      driverId != null && driverId!.trim().isNotEmpty;

  String get displayDriverName =>
      hasAssignedDriver && driverName.trim().isNotEmpty
          ? driverName.trim()
          : 'Not Assigned';

  String get displayBusCode {
    if (busNo.trim().isNotEmpty) return busNo.trim();
    if (routeNumber.trim().isNotEmpty) return routeNumber.trim();
    return '—';
  }

  /// Start stop label for cards.
  String get cardStartLabel {
    if (startLocation.trim().isNotEmpty) return startLocation.trim();
    if (stops.isNotEmpty && stops.first.stopName.trim().isNotEmpty) {
      return stops.first.stopName.trim();
    }
    return '—';
  }

  /// End stop label for cards.
  String get cardEndLabel {
    if (endLocation.trim().isNotEmpty) return endLocation.trim();
    if (stops.isNotEmpty && stops.last.stopName.trim().isNotEmpty) {
      return stops.last.stopName.trim();
    }
    return '—';
  }

  static bool looksLikeDuration(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return false;
    return t.contains('min') ||
        t.contains('hr') ||
        t.contains('hour') ||
        RegExp(r'^\d+\s*m(in)?$').hasMatch(t);
  }

  /// Departure clock for cards — never reuse estimatedTime / duration strings.
  String get cardDepartureTime {
    final d = departureTime.trim();
    if (d.isNotEmpty && !looksLikeDuration(d)) return d;
    if (stops.isNotEmpty &&
        stops.first.timeLabel.trim().isNotEmpty &&
        !looksLikeDuration(stops.first.timeLabel)) {
      return stops.first.timeLabel.trim();
    }
    return '';
  }

  /// Arrival clock for cards.
  String get cardArrivalTime {
    final a = arrivalTime.trim();
    if (a.isNotEmpty && !looksLikeDuration(a)) return a;
    if (stops.isNotEmpty &&
        stops.last.timeLabel.trim().isNotEmpty &&
        !looksLikeDuration(stops.last.timeLabel)) {
      return stops.last.timeLabel.trim();
    }
    return '';
  }

  /// Trip duration label (separate from stop clock times).
  String get cardDuration {
    final e = estimatedTime.trim();
    if (e.isNotEmpty) return e;
    return '';
  }

  factory RouteModel.fromMap(String id, Map<String, dynamic> map) {
    final rawDriverId = map['driverId']?.toString().trim();
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
      departureTime: map['departureTime']?.toString() ?? '',
      arrivalTime: map['arrivalTime']?.toString() ?? '',
      isActive: map['isActive'] ?? true,
      driverId: (rawDriverId == null || rawDriverId.isEmpty) ? null : rawDriverId,
      driverName: map['driverName']?.toString() ?? '',
      driverPhone: map['driverPhone']?.toString() ?? '',
      busId: map['busId']?.toString() ?? '',
      busNo: map['busNo']?.toString() ??
          map['assignedBusNumber']?.toString() ??
          '',
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
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'isActive': isActive,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'busId': busId,
      'busNo': busNo,
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
    String? departureTime,
    String? arrivalTime,
    bool? isActive,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? busId,
    String? busNo,
    bool clearDriver = false,
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
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      isActive: isActive ?? this.isActive,
      driverId: clearDriver ? null : (driverId ?? this.driverId),
      driverName: clearDriver ? '' : (driverName ?? this.driverName),
      driverPhone: clearDriver ? '' : (driverPhone ?? this.driverPhone),
      busId: clearDriver ? '' : (busId ?? this.busId),
      busNo: clearDriver ? '' : (busNo ?? this.busNo),
    );
  }
}

class RouteStop {
  final String stopName;
  final double lat;
  final double lng;
  final int order;
  /// Optional per-stop clock/ETA label (e.g. "07:45 AM").
  final String timeLabel;

  RouteStop({
    required this.stopName,
    required this.lat,
    required this.lng,
    required this.order,
    this.timeLabel = '',
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      stopName: map['stopName'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      order: map['order'] ?? 0,
      timeLabel: map['timeLabel']?.toString() ??
          map['eta']?.toString() ??
          map['time']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'lat': lat,
      'lng': lng,
      'order': order,
      if (timeLabel.isNotEmpty) 'timeLabel': timeLabel,
    };
  }
}
