class StudentModel {
  final String uid;
  final String name;
  final String regNumber;
  final String department;
  final String semester;
  final String email;
  final String phone;
  final String profileImage;
  final bool isActive;

  StudentModel({
    required this.uid,
    required this.name,
    required this.regNumber,
    required this.department,
    required this.semester,
    required this.email,
    required this.phone,
    required this.profileImage,
    this.isActive = true,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      uid: id,
      name: map['name'] ?? '',
      regNumber: map['regNumber'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'regNumber': regNumber,
      'department': department,
      'semester': semester,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'isActive': isActive,
      'role': 'student',
    };
  }
}
