import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_parse.dart';

/// Legacy type enum kept for older UI; mapped from [priority].
enum NoticeType { delay, emergency, general }

class NoticeModel {
  final String id;
  final String title;
  /// Body text (legacy field name was `description`).
  final String message;
  /// 'all' | 'drivers' | 'students'
  final String audience;
  /// 'normal' | 'important' | 'urgent'
  final String priority;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  /// Optional: notice aimed at one driver (migrated from alerts).
  final String? targetDriverId;

  NoticeModel({
    required this.id,
    required this.title,
    required this.message,
    this.audience = 'all',
    this.priority = 'normal',
    this.isActive = true,
    this.createdBy = 'Admin',
    DateTime? createdAt,
    this.expiresAt,
    this.targetDriverId,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  /// Legacy aliases used across older screens.
  String get description => message;
  String get postedBy => createdBy;
  DateTime get date => createdAt;
  String get targetAudience => audience;

  NoticeType get type {
    switch (priority) {
      case 'urgent':
        return NoticeType.emergency;
      case 'important':
        return NoticeType.delay;
      default:
        return NoticeType.general;
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!.toUtc());
  }

  bool get isVisibleNow => isActive && !isExpired;

  factory NoticeModel.fromMap(Map<String, dynamic> map, String docId) {
    final priority = _parsePriority(map);
    final audience = _parseAudience(map);
    final createdAt = _parseCreatedAt(map);
    final message = FirestoreParse.asString(
      map['message'] ?? map['description'],
    );
    final createdBy = FirestoreParse.asString(
      map['createdBy'] ?? map['postedBy'],
      'Admin',
    );
    final isActive = map['isActive'] != false;

    return NoticeModel(
      id: docId,
      title: FirestoreParse.asString(map['title']),
      message: message,
      audience: audience,
      priority: priority,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      expiresAt: _asDateTime(map['expiresAt']),
      targetDriverId: map['targetDriverId']?.toString() ??
          map['driverId']?.toString(),
    );
  }

  static String _parseAudience(Map<String, dynamic> map) {
    final raw = FirestoreParse.asString(
      map['audience'] ?? map['targetAudience'],
      'all',
    ).toLowerCase();
    if (raw == 'drivers' || raw == 'students' || raw == 'all') return raw;
    if (raw == 'all_drivers') return 'drivers';
    return 'all';
  }

  static String _parsePriority(Map<String, dynamic> map) {
    final fromPriority =
        FirestoreParse.asString(map['priority']).toLowerCase();
    if (fromPriority == 'urgent' ||
        fromPriority == 'important' ||
        fromPriority == 'normal') {
      return fromPriority;
    }
    // Legacy notice `type`
    switch (FirestoreParse.asString(map['type']).toLowerCase()) {
      case 'emergency':
        return 'urgent';
      case 'delay':
        return 'important';
      default:
        break;
    }
    // Migrated alert `severity`
    switch (FirestoreParse.asString(map['severity']).toLowerCase()) {
      case 'critical':
        return 'urgent';
      case 'warning':
        return 'important';
      case 'info':
        return 'normal';
      default:
        return 'normal';
    }
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> map) {
    return _asDateTime(map['createdAt']) ??
        FirestoreParse.asDateTimeOrNow(map['date']);
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
      // Legacy keys so older readers keep working.
      'description': message,
      'audience': audience,
      'targetAudience': audience,
      'priority': priority,
      'type': type.name,
      'isActive': isActive,
      'createdBy': createdBy,
      'postedBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
      'date': Timestamp.fromDate(createdAt.toUtc()),
      'expiresAt':
          expiresAt == null ? null : Timestamp.fromDate(expiresAt!.toUtc()),
      if (targetDriverId != null && targetDriverId!.isNotEmpty)
        'targetDriverId': targetDriverId,
      'universityId': 'uog',
    };
  }

  bool isVisibleTo(String role, {String? driverUid}) {
    if (!isVisibleNow) return false;
    if (targetDriverId != null && targetDriverId!.isNotEmpty) {
      return role == 'driver' && driverUid == targetDriverId;
    }
    if (audience == 'all') return true;
    if (role == 'driver') return audience == 'drivers';
    if (role == 'student') return audience == 'students';
    return true; // admin
  }

  NoticeModel copyWith({
    String? id,
    String? title,
    String? message,
    String? audience,
    String? priority,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? targetDriverId,
    bool clearExpiresAt = false,
    bool clearTargetDriverId = false,
  }) {
    return NoticeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      audience: audience ?? this.audience,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      targetDriverId: clearTargetDriverId
          ? null
          : (targetDriverId ?? this.targetDriverId),
    );
  }
}
