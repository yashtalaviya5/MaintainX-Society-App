import 'package:cloud_firestore/cloud_firestore.dart';

class FlatModel {
  final String id;
  final String societyId;
  final String flatNumber;
  final String ownerName;
  final String phone;
  final DateTime createdAt;

  FlatModel({
    required this.id,
    required this.societyId,
    required this.flatNumber,
    required this.ownerName,
    required this.phone,
    required this.createdAt,
  });

  factory FlatModel.fromMap(Map<String, dynamic> map, String id) {
    return FlatModel(
      id: id,
      societyId: map['societyId'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      ownerName: map['ownerName'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'flatNumber': flatNumber,
      'ownerName': ownerName,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
