import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String title;
  final String message;
  /// info | warning | critical
  final String severity;
  /// all_drivers | specific_driver
  final String target;
  final String? driverId;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    this.severity = 'info',
    this.target = 'all_drivers',
    this.driverId,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!.toUtc());
  }

  bool get isVisibleNow => isActive && !isExpired;

  bool isVisibleToDriver(String uid) {
    if (!isVisibleNow) return false;
    if (target == 'all_drivers') return true;
    return target == 'specific_driver' && driverId == uid;
  }

  factory AlertModel.fromMap(Map<String, dynamic> map, String docId) {
    return AlertModel(
      id: docId,
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'info',
      target: map['target']?.toString() ?? 'all_drivers',
      driverId: map['driverId']?.toString(),
      isActive: map['isActive'] != false,
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt: _asDateTime(map['createdAt']) ?? DateTime.now().toUtc(),
      expiresAt: _asDateTime(map['expiresAt']),
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'severity': severity,
      'target': target,
      'driverId': driverId,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'expiresAt':
          expiresAt == null ? null : Timestamp.fromDate(expiresAt!.toUtc()),
    };
  }

  AlertModel copyWith({
    String? id,
    String? title,
    String? message,
    String? severity,
    String? target,
    String? driverId,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    bool clearDriverId = false,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      target: target ?? this.target,
      driverId: clearDriverId ? null : (driverId ?? this.driverId),
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }
}
