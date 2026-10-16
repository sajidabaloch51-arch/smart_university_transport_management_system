import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class DriverModel extends UserModel {
  final String driverId; // Employee ID
  final String? licenseNumber;
  final String? cnicOrLicense;
  final DateTime? licenseExpiryDate;
  final String? address;
  final int? experienceYears;
  final String status; // 'Active', 'Inactive', 'On Leave'
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
    this.licenseNumber,
    this.cnicOrLicense,
    this.licenseExpiryDate,
    this.address,
    this.experienceYears,
    this.status = 'Active',
    this.profileImg = '',
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
      licenseNumber: map['licenseNumber'],
      cnicOrLicense: map['cnicOrLicense'],
      licenseExpiryDate: map['licenseExpiryDate'] != null
          ? (map['licenseExpiryDate'] as Timestamp).toDate()
          : null,
      address: map['address'],
      experienceYears: map['experienceYears'],
      status: map['status'] ?? 'Active',
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

  /// Lean Firestore payload — drops unused license/address clutter.
  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'driverId': driverId,
      'status': status,
      'assignedBusId': assignedBusId,
      'assignedBusNumber': assignedBusNumber,
      'assignedRouteId': assignedRouteId,
      'assignedRouteName': assignedRouteName,
      'isOnDuty': isOnDuty,
    };

    if (profileImg.isNotEmpty) map['profileImg'] = profileImg;
    if (experienceYears != null) map['experienceYears'] = experienceYears;
    if (lastDutyStart != null) {
      map['lastDutyStart'] = Timestamp.fromDate(lastDutyStart!);
    }
    return map;
  }

  DriverModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? driverId,
    String? licenseNumber,
    String? cnicOrLicense,
    DateTime? licenseExpiryDate,
    String? address,
    int? experienceYears,
    String? status,
    String? profileImg,
    String? assignedBusId,
    String? assignedBusNumber,
    String? assignedRouteId,
    String? assignedRouteName,
    bool? isOnDuty,
    DateTime? lastDutyStart,
  }) {
    return DriverModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      driverId: driverId ?? this.driverId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      cnicOrLicense: cnicOrLicense ?? this.cnicOrLicense,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      address: address ?? this.address,
      experienceYears: experienceYears ?? this.experienceYears,
      status: status ?? this.status,
      profileImg: profileImg ?? this.profileImg,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      assignedBusNumber: assignedBusNumber ?? this.assignedBusNumber,
      assignedRouteId: assignedRouteId ?? this.assignedRouteId,
      assignedRouteName: assignedRouteName ?? this.assignedRouteName,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      lastDutyStart: lastDutyStart ?? this.lastDutyStart,
    );
  }
}
