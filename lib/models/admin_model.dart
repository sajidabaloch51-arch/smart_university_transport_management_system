import 'user_model.dart';

class AdminModel extends UserModel {
  final String university;
  final String profilePhoto;
  final String employeeId;
  final String designation;
  final String officeLocation;

  AdminModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required this.university,
    required this.profilePhoto,
    required this.employeeId,
    required this.designation,
    required this.officeLocation,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'admin',
      university: map['university'] ?? '',
      profilePhoto: map['profilePhoto'] ?? '',
      employeeId: map['employeeId'] ?? '',
      designation: map['designation'] ?? '',
      officeLocation: map['officeLocation'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'university': university,
      'profilePhoto': profilePhoto,
      'employeeId': employeeId,
      'designation': designation,
      'officeLocation': officeLocation,
    });
    return map;
  }
}
