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
      'verificationStatus': verificationStatus,
    });
    return map;
  }
}
