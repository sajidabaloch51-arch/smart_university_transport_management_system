import 'package:cloud_firestore/cloud_firestore.dart';

enum NoticeType { delay, emergency, general }

class NoticeModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final NoticeType type;
  final String postedBy;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.postedBy,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String docId) {
    return NoticeModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: _parseNoticeType(map['type']),
      postedBy: map['postedBy'] ?? 'Admin',
    );
  }

  static NoticeType _parseNoticeType(String? type) {
    switch (type?.toLowerCase()) {
      case 'emergency':
        return NoticeType.emergency;
      case 'delay':
        return NoticeType.delay;
      default:
        return NoticeType.general;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'postedBy': postedBy,
    };
  }
}
