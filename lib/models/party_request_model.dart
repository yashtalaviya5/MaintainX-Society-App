import 'package:cloud_firestore/cloud_firestore.dart';

class PartyRequestModel {
  final String id;
  final String societyId;
  final String userId;
  final String flatNumber;
  final String userName;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  PartyRequestModel({
    required this.id,
    required this.societyId,
    required this.userId,
    required this.flatNumber,
    required this.userName,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
  });

  factory PartyRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return PartyRequestModel(
      id: id,
      societyId: map['societyId'] ?? '',
      userId: map['userId'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      userName: map['userName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: _parseDate(map['date']),
      time: map['time'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'societyId': societyId,
    'userId': userId,
    'flatNumber': flatNumber,
    'userName': userName,
    'title': title,
    'description': description,
    'date': Timestamp.fromDate(date),
    'time': time,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
