import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String societyId;
  final String flatId;
  final String userId;
  final String title;
  final String description;
  final String status; // "open", "in-progress", "resolved"
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.societyId,
    required this.flatId,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      societyId: map['societyId'] ?? '',
      flatId: map['flatId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'flatId': flatId,
      'userId': userId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in-progress';
  bool get isResolved => status == 'resolved';
}
