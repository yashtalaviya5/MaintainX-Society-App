import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String societyId;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.createdAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      societyId: map['societyId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: _parseDate(map['date']),
      time: map['time'] ?? '',
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
    'title': title,
    'description': description,
    'date': Timestamp.fromDate(date),
    'time': time,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  bool get isUpcoming => date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
}
