class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // student, driver, admin
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'isActive': isActive,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    role: map['role'] ?? 'student',
    isActive: map['isActive'] ?? true,
  );
}
