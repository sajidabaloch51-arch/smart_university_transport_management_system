import 'user_model.dart';

class StudentModel extends UserModel {
  final String regNumber;
  final String fatherName;
  final String gender;
  final String dob;
  final String department;
  final String semester;
  final String profileImage;
  final String routeAddress;
  final String rollNo;
  final String? assignedRouteId;
  final String? assignedRouteName;
  final String? assignedBusId;
  final String? assignedBusName;
  final String? assignedBusCode;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final String? assignedDepartureTime;
  final String? assignedArrivalTime;
  final String verificationStatus; // pending, approved, rejected

  StudentModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required this.regNumber,
    required this.fatherName,
    required this.gender,
    required this.dob,
    required this.department,
    required this.semester,
    required this.profileImage,
    required this.routeAddress,
    required this.rollNo,
    this.assignedRouteId,
    this.assignedRouteName,
    this.assignedBusId,
    this.assignedBusName,
    this.assignedBusCode,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.assignedDepartureTime,
    this.assignedArrivalTime,
    this.verificationStatus = 'pending',
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      uid: id,
      name: map['name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'student',
      regNumber: map['regNumber'] ?? '',
      fatherName: map['fatherName'] ?? '',
      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      profileImage: map['profileImage'] ?? map['profilePhoto'] ?? '',
      routeAddress: map['routeAddress'] ?? '',
      rollNo: map['rollNo'] ?? map['serialNumber'] ?? '',
      assignedRouteId: map['assignedRouteId'],
      assignedRouteName: map['assignedRouteName'],
      assignedBusId: map['assignedBusId'],
      assignedBusName: map['assignedBusName'],
      assignedBusCode: map['assignedBusCode'],
      assignedDriverId: map['assignedDriverId'],
      assignedDriverName: map['assignedDriverName'],
      assignedDriverPhone: map['assignedDriverPhone'],
      assignedDepartureTime: map['assignedDepartureTime'],
      assignedArrivalTime: map['assignedArrivalTime'],
      verificationStatus: map['verificationStatus'] ?? 'pending',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'regNumber': regNumber,
      'fatherName': fatherName,
      'gender': gender,
      'dob': dob,
      'department': department,
      'semester': semester,
      'profileImage': profileImage,
      'routeAddress': routeAddress,
      'rollNo': rollNo,
      'assignedRouteId': assignedRouteId,
      'assignedRouteName': assignedRouteName,
      'assignedBusId': assignedBusId,
      'assignedBusName': assignedBusName,
      'assignedBusCode': assignedBusCode,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedDriverPhone': assignedDriverPhone,
      'assignedDepartureTime': assignedDepartureTime,
      'assignedArrivalTime': assignedArrivalTime,
      'verificationStatus': verificationStatus,
    });
    return map;
  }
}
