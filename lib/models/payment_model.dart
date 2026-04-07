import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String societyId;
  final String flatId;
  final int month; // 1-12
  final int year;
  final String status; // "paid" or "unpaid"
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.societyId,
    required this.flatId,
    required this.month,
    required this.year,
    required this.status,
    this.paidAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      societyId: map['societyId'] ?? '',
      flatId: map['flatId'] ?? '',
      month: map['month'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      status: map['status'] ?? 'unpaid',
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'flatId': flatId,
      'month': month,
      'year': year,
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  /// Check if payment is marked as paid
  bool get isPaid => status == 'paid';

  /// Get month name from month number
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
