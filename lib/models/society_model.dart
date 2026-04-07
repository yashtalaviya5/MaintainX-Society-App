import 'package:cloud_firestore/cloud_firestore.dart';

class SocietyModel {
  final String id;
  final String societyName;
  final String city;
  final String address;
  final String adminUserId;
  final DateTime createdAt;

  SocietyModel({
    required this.id,
    required this.societyName,
    required this.city,
    required this.address,
    required this.adminUserId,
    required this.createdAt,
  });

  factory SocietyModel.fromMap(Map<String, dynamic> map, String id) {
    return SocietyModel(
      id: id,
      societyName: map['societyName'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      adminUserId: map['adminUserId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyName': societyName,
      'city': city,
      'address': address,
      'adminUserId': adminUserId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
