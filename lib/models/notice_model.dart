import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String societyId;
  final String title;
  final String description;
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    return NoticeModel(
      id: id,
      societyId: map['societyId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
