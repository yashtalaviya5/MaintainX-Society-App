import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String societyId;
  final String? userId; // null = all users in society
  final String? senderId; // ID of the person who triggered the notification
  final String? targetRole; // e.g., 'admin' or 'resident'
  final String title;
  final String body;
  final String type; // notice, event, meeting, complaint, party
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.societyId,
    this.userId,
    this.senderId,
    this.targetRole,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      societyId: map['societyId'] ?? '',
      userId: map['userId'],
      senderId: map['senderId'],
      targetRole: map['targetRole'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'societyId': societyId,
    'userId': userId,
    'senderId': senderId,
    'targetRole': targetRole,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
