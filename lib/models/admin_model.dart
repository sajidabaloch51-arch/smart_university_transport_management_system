class AdminModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String university;
  final String profilePhoto;

  AdminModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.university,
    required this.profilePhoto,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      university: map['university'] ?? '',
      profilePhoto: map['profilePhoto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'university': university,
      'profilePhoto': profilePhoto,
    };
  }
}
