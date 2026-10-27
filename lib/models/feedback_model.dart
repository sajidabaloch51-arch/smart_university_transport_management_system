import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String category;
  final String message;
  final String studentUid;
  final String status; // new | reviewed | resolved
  final DateTime createdAt;
  final String? studentName;
  final String? rollNo;
  final String? department;
  final String? adminNote;

  const FeedbackModel({
    required this.id,
    required this.category,
    required this.message,
    required this.studentUid,
    required this.status,
    required this.createdAt,
    this.studentName,
    this.rollNo,
    this.department,
    this.adminNote,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    final created = map['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawMessage = (map['message'] ??
            map['comment'] ??
            map['text'] ??
            map['feedback'] ??
            '')
        .toString();
    final rawCategory =
        (map['category'] ?? map['type'] ?? map['feedbackCategory'] ?? 'Other')
            .toString();

    return FeedbackModel(
      id: id,
      category: rawCategory,
      message: rawMessage,
      studentUid: (map['studentUid'] ?? map['uid'] ?? map['userId'] ?? '')
          .toString(),
      status: (map['status'] ?? 'new').toString(),
      createdAt: createdAt,
      studentName: map['studentName']?.toString(),
      rollNo: map['rollNo']?.toString(),
      department: map['department']?.toString(),
      adminNote: map['adminNote']?.toString(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'category': category,
      'message': message,
      'studentUid': studentUid,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      if (studentName != null && studentName!.isNotEmpty)
        'studentName': studentName,
      if (rollNo != null && rollNo!.isNotEmpty) 'rollNo': rollNo,
      if (department != null && department!.isNotEmpty)
        'department': department,
    };
  }
}
