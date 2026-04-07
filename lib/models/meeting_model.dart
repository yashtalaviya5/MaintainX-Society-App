import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String societyId;
  final String title;
  final String agenda;
  final DateTime date;
  final String time;
  final String location;
  final DateTime createdAt;

  MeetingModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.agenda,
    required this.date,
    required this.time,
    required this.location,
    required this.createdAt,
  });

  factory MeetingModel.fromMap(Map<String, dynamic> map, String id) {
    return MeetingModel(
      id: id,
      societyId: map['societyId'] ?? '',
      title: map['title'] ?? '',
      agenda: map['agenda'] ?? '',
      date: _parseDate(map['date']),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
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
    'agenda': agenda,
    'date': Timestamp.fromDate(date),
    'time': time,
    'location': location,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  bool get isUpcoming => date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
}
