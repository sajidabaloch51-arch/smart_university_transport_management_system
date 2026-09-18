import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map, String docId) {
    return ScheduleModel(
      id: docId,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      departureTime: map['departureTime'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      shift: map['shift'] ?? 'Morning',
      vehicleNo: map['vehicleNo'] ?? map['busNumber'] ?? '',
      status: map['status'] ?? 'Scheduled',
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
    );
  }
}
