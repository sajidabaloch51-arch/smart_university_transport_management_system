import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class DriverModel extends UserModel {
  final String driverId; // Employee ID
  final String licenseNumber;
  final String profileImg;
  final String assignedBusId;
  final String assignedBusNumber;
  final String assignedRouteId;
  final String assignedRouteName;
  final bool isOnDuty;
  final DateTime? lastDutyStart;

  DriverModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required this.driverId,
    required this.licenseNumber,
    required this.profileImg,
    required this.assignedBusId,
    required this.assignedBusNumber,
    required this.assignedRouteId,
    required this.assignedRouteName,
    required this.isOnDuty,
    this.lastDutyStart,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map, String docId) {
    return DriverModel(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'driver',
      driverId: map['driverId'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      profileImg: map['profileImg'] ?? '',
      assignedBusId: map['assignedBusId'] ?? '',
      assignedBusNumber: map['assignedBusNumber'] ?? '',
      assignedRouteId: map['assignedRouteId'] ?? '',
      assignedRouteName: map['assignedRouteName'] ?? '',
      isOnDuty: map['isOnDuty'] ?? false,
      lastDutyStart: map['lastDutyStart'] != null 
          ? (map['lastDutyStart'] as Timestamp).toDate() 
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'driverId': driverId,
      'licenseNumber': licenseNumber,
      'profileImg': profileImg,
      'assignedBusId': assignedBusId,
      'assignedBusNumber': assignedBusNumber,
      'assignedRouteId': assignedRouteId,
      'assignedRouteName': assignedRouteName,
      'isOnDuty': isOnDuty,
      'lastDutyStart': lastDutyStart != null ? Timestamp.fromDate(lastDutyStart!) : null,
    });
    return map;
  }
}
