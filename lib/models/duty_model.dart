import 'package:cloud_firestore/cloud_firestore.dart';

class DutyModel {
  final String id;
  final String driverId;
  final String driverName;
  final String busNo;
  /// Stable Firestore routes/{id}. Prefer this over [route] name matching.
  final String routeId;
  final String route;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final String dutyDate;
  final String notes;
  /// scheduled | active | completed | cancelled
  final String status;
  final String createdBy;
  final DateTime createdAt;

  const DutyModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.busNo,
    this.routeId = '',
    required this.route,
    required this.shiftStart,
    required this.shiftEnd,
    required this.dutyDate,
    this.notes = '',
    this.status = 'scheduled',
    required this.createdBy,
    required this.createdAt,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isActiveOrScheduled =>
      status == 'scheduled' || status == 'active';

  factory DutyModel.fromMap(Map<String, dynamic> map, String docId) {
    return DutyModel(
      id: docId,
      driverId: map['driverId']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? '',
      busNo: map['busNo']?.toString() ?? '',
      routeId: map['routeId']?.toString() ?? '',
      route: map['route']?.toString() ?? '',
      shiftStart: _asDateTime(map['shiftStart']) ?? DateTime.now().toUtc(),
      shiftEnd: _asDateTime(map['shiftEnd']) ?? DateTime.now().toUtc(),
      dutyDate: map['dutyDate']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? 'scheduled',
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt: _asDateTime(map['createdAt']) ?? DateTime.now().toUtc(),
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'busNo': busNo,
      'routeId': routeId,
      'route': route,
      'shiftStart': Timestamp.fromDate(shiftStart.toUtc()),
      'shiftEnd': Timestamp.fromDate(shiftEnd.toUtc()),
      'dutyDate': dutyDate,
      'notes': notes,
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    };
  }

  DutyModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? busNo,
    String? routeId,
    String? route,
    DateTime? shiftStart,
    DateTime? shiftEnd,
    String? dutyDate,
    String? notes,
    String? status,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return DutyModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      busNo: busNo ?? this.busNo,
      routeId: routeId ?? this.routeId,
      route: route ?? this.route,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      dutyDate: dutyDate ?? this.dutyDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// True when [a,b) intervals overlap (exclusive end equality allowed).
  static bool overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }
}
