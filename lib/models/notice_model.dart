import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String universityId;
  final String title;
  final String body;
  final String type; // delay, cancellation, general, emergency
  final String targetRole; // all, student, driver
  final String postedBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime expiresAt;

  NoticeModel({
    required this.id,
    required this.universityId,
    required this.title,
    required this.body,
    required this.type,
    required this.targetRole,
    required this.postedBy,
    this.isActive = true,
    required this.createdAt,
    required this.expiresAt,
  });

  factory NoticeModel.fromMap(String id, Map<String, dynamic> map) {
    return NoticeModel(
      id: id,
      universityId: map['universityId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      targetRole: map['targetRole'] ?? 'all',
      postedBy: map['postedBy'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'universityId': universityId,
      'title': title,
      'body': body,
      'type': type,
      'targetRole': targetRole,
      'postedBy': postedBy,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}
