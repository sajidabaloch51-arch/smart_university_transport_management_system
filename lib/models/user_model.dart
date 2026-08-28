class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String universityId;
  final String profilePhotoUrl;
  final String assignedRouteId;
  final String regNumber;
  final String fcmToken;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.universityId,
    this.profilePhotoUrl = '',
    this.assignedRouteId = '',
    this.regNumber = '',
    this.fcmToken = '',
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      universityId: map['universityId'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'] ?? '',
      assignedRouteId: map['assignedRouteId'] ?? '',
      regNumber: map['regNumber'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'universityId': universityId,
      'profilePhotoUrl': profilePhotoUrl,
      'assignedRouteId': assignedRouteId,
      'regNumber': regNumber,
      'fcmToken': fcmToken,
      'isActive': isActive,
    };
  }
}
