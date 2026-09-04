import 'user_model.dart';

class AdminModel extends UserModel {
  final String university;
  final String profilePhoto;

  AdminModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required this.university,
    required this.profilePhoto,
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
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'university': university,
      'profilePhoto': profilePhoto,
    });
    return map;
  }
}
