import 'user_model.dart';

class StudentModel extends UserModel {
  final String regNumber;
  final String department;
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
  /// Salted hash only when Firebase Auth is unavailable — never plaintext.
  final String? passwordHash;
  final bool termsAccepted;
  final String? termsVersion;

  StudentModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    required this.regNumber,
    required this.department,
    this.profileImage = '',
    this.routeAddress = '',
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
    this.passwordHash,
    this.termsAccepted = false,
    this.termsVersion,
  });

  /// Ignores legacy Firestore keys: fatherName, gender, dob, semester.
  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      uid: id,
      name: map['name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'student',
      regNumber: map['regNumber'] ?? '',
      department: map['department'] ?? '',
      profileImage: map['profileImage'] ?? map['profilePhoto'] ?? '',
      routeAddress: map['routeAddress'] ?? '',
      rollNo: map['rollNo'] ?? map['serialNumber'] ?? '',
      assignedRouteId: map['assignedRouteId'],
      assignedRouteName: map['assignedRouteName'],
      assignedBusId: map['assignedBusId'],
      assignedBusName: map['assignedBusName'],
      assignedBusCode: map['assignedBusCode'] ?? map['assignedBusName'],
      assignedDriverId: map['assignedDriverId'],
      assignedDriverName: map['assignedDriverName'],
      assignedDriverPhone: map['assignedDriverPhone'],
      assignedDepartureTime: map['assignedDepartureTime'],
      assignedArrivalTime: map['assignedArrivalTime'],
      verificationStatus: _normalizeVerificationStatus(
        map['verificationStatus'],
      ),
      passwordHash: map['passwordHash'] as String?,
      termsAccepted: map['termsAccepted'] == true,
      termsVersion: map['termsVersion']?.toString(),
    );
  }

  /// Lean Firestore payload — never writes fatherName/gender/dob/semester
  /// (legacy values in existing docs are left untouched by merge writes that
  /// omit those keys).
  @override
  Map<String, dynamic> toMap() {
    final rollKey = rollNo
        .trim()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    final map = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'regNumber': regNumber,
      'department': department,
      'rollNo': rollNo.trim(),
      'rollNoKey': rollKey,
      'verificationStatus': verificationStatus,
      'termsAccepted': termsAccepted,
    };

    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      map[key] = value;
    }

    put('profileImage', profileImage);
    put('routeAddress', routeAddress);
    put('assignedRouteId', assignedRouteId);
    put('assignedRouteName', assignedRouteName);
    put('assignedBusId', assignedBusId);
    put('assignedBusCode', assignedBusCode ?? assignedBusName);
    put('assignedDriverId', assignedDriverId);
    put('assignedDriverName', assignedDriverName);
    put('assignedDriverPhone', assignedDriverPhone);
    put('assignedDepartureTime', assignedDepartureTime);
    put('assignedArrivalTime', assignedArrivalTime);
    put('passwordHash', passwordHash);
    put('termsVersion', termsVersion);
    return map;
  }

  static String _normalizeVerificationStatus(dynamic raw) {
    final s = (raw ?? 'pending').toString().trim().toLowerCase();
    if (s == 'approved' || s == 'rejected' || s == 'pending') return s;
    return s.isEmpty ? 'pending' : s;
  }
}
