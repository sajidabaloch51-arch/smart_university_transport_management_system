import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_parse.dart';

class ScheduleModel {
  final String id;
  final String driverId;
  final String driverName;
  final String routeId;
  final String routeName;
  final DateTime date;
  final String departureTime;
  final String arrivalTime;
  final String shift; // 'Morning', 'Evening', 'Night'
  final String vehicleNo;
  final String status; // 'Scheduled', 'Completed', 'Cancelled'
  final List<String> operationalDays;

  ScheduleModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.routeId,
    required this.routeName,
    required this.date,
    required this.departureTime,
    required this.arrivalTime,
    required this.shift,
    required this.vehicleNo,
    required this.status,
    this.operationalDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  });

  /// Null-safe / type-tolerant. Never throws on a single bad field shape.
  factory ScheduleModel.fromMap(Map<String, dynamic> map, String docId) {
    return ScheduleModel(
      id: docId,
      driverId: FirestoreParse.asString(map['driverId']),
      driverName: FirestoreParse.asString(map['driverName']),
      routeId: FirestoreParse.asString(map['routeId']),
      routeName: FirestoreParse.asString(map['routeName']),
      date: FirestoreParse.asDateTimeOrNow(map['date']),
      departureTime: FirestoreParse.asString(map['departureTime']),
      arrivalTime: FirestoreParse.asString(map['arrivalTime']),
      shift: FirestoreParse.asString(map['shift'], 'Morning'),
      vehicleNo: FirestoreParse.asString(
        map['vehicleNo'] ?? map['busNumber'],
      ),
      status: FirestoreParse.asString(map['status'], 'Scheduled'),
      operationalDays: FirestoreParse.asStringList(
        map['operationalDays'],
        fallback: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'routeId': routeId,
      'routeName': routeName,
      'date': Timestamp.fromDate(date),
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'shift': shift,
      'vehicleNo': vehicleNo,
      'status': status,
      'operationalDays': operationalDays,
    };
  }

  ScheduleModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? routeId,
    String? routeName,
    DateTime? date,
    String? departureTime,
    String? arrivalTime,
    String? shift,
    String? vehicleNo,
    String? status,
    List<String>? operationalDays,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      date: date ?? this.date,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      shift: shift ?? this.shift,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      status: status ?? this.status,
      operationalDays: operationalDays ?? this.operationalDays,
    );
  }
}
