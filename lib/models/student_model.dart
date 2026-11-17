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
  /// Tolerant of missing / wrong-typed fields so one bad doc cannot fail a list.
  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    String str(dynamic v, [String fallback = '']) =>
        v == null ? fallback : v.toString();
    String? strOrNull(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    return StudentModel(
      uid: id,
      name: str(map['name'] ?? map['fullName']),
      email: str(map['email']),
      phone: str(map['phone']),
      role: str(map['role'], 'student'),
      regNumber: str(map['regNumber']),
      department: str(map['department']),
      profileImage: str(map['profileImage'] ?? map['profilePhoto']),
      routeAddress: str(map['routeAddress']),
      rollNo: str(map['rollNo'] ?? map['serialNumber']),
      assignedRouteId: strOrNull(map['assignedRouteId']),
      assignedRouteName: strOrNull(map['assignedRouteName']),
      assignedBusId: strOrNull(map['assignedBusId']),
      assignedBusName: strOrNull(map['assignedBusName']),
      assignedBusCode: strOrNull(map['assignedBusCode'] ?? map['assignedBusName']),
      assignedDriverId: strOrNull(map['assignedDriverId']),
      assignedDriverName: strOrNull(map['assignedDriverName']),
      assignedDriverPhone: strOrNull(map['assignedDriverPhone']),
      assignedDepartureTime: strOrNull(map['assignedDepartureTime']),
      assignedArrivalTime: strOrNull(map['assignedArrivalTime']),
      verificationStatus: _normalizeVerificationStatus(
        map['verificationStatus'],
      ),
      passwordHash: strOrNull(map['passwordHash']),
      termsAccepted: map['termsAccepted'] == true ||
          map['termsAccepted'] == 1 ||
          map['termsAccepted']?.toString().trim().toLowerCase() == 'true',
      termsVersion: strOrNull(map['termsVersion']),
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
