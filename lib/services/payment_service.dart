import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

/// Service for payment-related Firestore operations
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all payments for a specific flat
  Stream<List<PaymentModel>> streamPaymentsForFlat(String flatId) {
    return _firestore
        .collection('payments')
        .where('flatId', isEqualTo: flatId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get all payments for a society (one-time)
  Future<List<PaymentModel>> getPaymentsForSociety(String societyId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('societyId', isEqualTo: societyId)
        .get();
    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all payments for a specific flat (one-time)
  Future<List<PaymentModel>> getPaymentsForFlat(String flatId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('flatId', isEqualTo: flatId)
        .get();
    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Mark a specific month as Paid
  Future<void> markPaid({
    required String societyId,
    required String flatId,
    required int month,
    required int year,
  }) async {
    // Check if payment record exists for this month
    final existing = await _firestore
        .collection('payments')
        .where('flatId', isEqualTo: flatId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing record
      await existing.docs.first.reference.update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new payment record
      await _firestore.collection('payments').add({
        'societyId': societyId,
        'flatId': flatId,
        'month': month,
        'year': year,
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Mark a specific month as Unpaid
  Future<void> markUnpaid({
    required String flatId,
    required int month,
    required int year,
  }) async {
    final existing = await _firestore
        .collection('payments')
        .where('flatId', isEqualTo: flatId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'status': 'unpaid',
        'paidAt': null,
      });
    }
  }

  /// Get the maintenance amount applicable for a given month/year
  /// from the amountHistory list.
  /// amountHistory is sorted by effectiveDate ascending.
  /// Returns the amount from the latest entry whose effectiveDate <= the given month/year.
  static double getAmountForMonth(
      List<Map<String, dynamic>> amountHistory, int month, int year) {
    if (amountHistory.isEmpty) return 0;

    double applicableAmount = amountHistory.first['amount']?.toDouble() ?? 0;

    for (final entry in amountHistory) {
      final effMonth = entry['effectiveMonth'] as int;
      final effYear = entry['effectiveYear'] as int;
      final amount = (entry['amount'] ?? 0).toDouble();

      // If this entry's effective date is <= the target month/year
      if (effYear < year || (effYear == year && effMonth <= month)) {
        applicableAmount = amount;
      } else {
        break; // amountHistory is sorted, so no need to check further
      }
    }

    return applicableAmount;
  }

  /// Calculate total due for a flat based on unpaid months
  /// Uses amountHistory to get the correct rate for each month.
  /// Returns a map with 'totalDue', 'unpaidMonths', and 'paidMonths'
  Map<String, dynamic> calculateDues({
    required List<PaymentModel> payments,
    required List<Map<String, dynamic>> amountHistory,
    required int startMonth,
    required int startYear,
  }) {
    final now = DateTime.now();
    double totalDue = 0;
    int unpaidMonths = 0;
    int paidMonths = 0;

    int currentMonth = startMonth;
    int currentYear = startYear;

    while (currentYear < now.year ||
        (currentYear == now.year && currentMonth <= now.month)) {
      // Get the applicable amount for this month
      final monthAmount =
          getAmountForMonth(amountHistory, currentMonth, currentYear);

      // Check if there's a paid record for this month
      final payment = payments.where(
        (p) => p.month == currentMonth && p.year == currentYear,
      );

      if (payment.isNotEmpty && payment.first.isPaid) {
        paidMonths++;
      } else {
        unpaidMonths++;
        totalDue += monthAmount;
      }

      // Move to next month
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    return {
      'totalDue': totalDue,
      'unpaidMonths': unpaidMonths,
      'paidMonths': paidMonths,
    };
  }

  /// Load the amount history from Firestore for a society
  static Future<List<Map<String, dynamic>>> loadAmountHistory(
      String societyId) async {
    final doc = await FirebaseFirestore.instance
        .collection('maintenance_settings')
        .doc(societyId)
        .get();

    if (!doc.exists) return [];

    final data = doc.data()!;
    final List<dynamic> history = data['amountHistory'] ?? [];

    // If there's no history yet but there IS a legacy 'amount' field,
    // create a single history entry from it (migration support)
    if (history.isEmpty && data.containsKey('amount')) {
      return [
        {
          'amount': (data['amount'] ?? 0).toDouble(),
          'effectiveMonth': 1,
          'effectiveYear': 2020, // far enough back
        }
      ];
    }

    final result = history
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    // Sort by effective date ascending
    result.sort((a, b) {
      final yearCmp =
          (a['effectiveYear'] as int).compareTo(b['effectiveYear'] as int);
      if (yearCmp != 0) return yearCmp;
      return (a['effectiveMonth'] as int)
          .compareTo(b['effectiveMonth'] as int);
    });
    return result;
  }

  /// Get the current (latest) maintenance amount from history
  static double getCurrentAmount(List<Map<String, dynamic>> amountHistory) {
    if (amountHistory.isEmpty) return 0;
    return (amountHistory.last['amount'] ?? 0).toDouble();
  }
}
