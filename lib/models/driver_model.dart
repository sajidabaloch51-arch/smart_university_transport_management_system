import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImg;
  final String assignedBusId;
  final String assignedBusNumber;
  final String assignedRouteId;
  final String assignedRouteName;
  final bool isOnDuty;
  final DateTime? lastDutyStart;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
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
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profileImg': profileImg,
      'assignedBusId': assignedBusId,
      'assignedBusNumber': assignedBusNumber,
      'assignedRouteId': assignedRouteId,
      'assignedRouteName': assignedRouteName,
      'isOnDuty': isOnDuty,
      'lastDutyStart': lastDutyStart != null ? Timestamp.fromDate(lastDutyStart!) : null,
    };
  }
}
