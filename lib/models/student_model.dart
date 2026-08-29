import 'user_model.dart';

class StudentModel extends UserModel {
  final String regNumber;
  final String fatherName;
  final String gender;
  final String dob;
  final String department;
  final String semester;
  final String profileImage;

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
    });
    return map;
  }
}
