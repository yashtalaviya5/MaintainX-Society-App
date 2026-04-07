import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/payment_service.dart';
import '../../models/flat_model.dart';
import '../../models/payment_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Flat payment details - month-wise payment view with toggle
class FlatPaymentDetailsScreen extends StatefulWidget {
  final FlatModel flat;
  final String societyId;
  final List<Map<String, dynamic>> amountHistory;

  const FlatPaymentDetailsScreen({
    super.key,
    required this.flat,
    required this.societyId,
    required this.amountHistory,
  });

  @override
  State<FlatPaymentDetailsScreen> createState() =>
      _FlatPaymentDetailsScreenState();
}

class _FlatPaymentDetailsScreenState extends State<FlatPaymentDetailsScreen> {
  final _paymentService = PaymentService();
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments =
        await _paymentService.getPaymentsForFlat(widget.flat.id);
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  /// Get payment status for a specific month/year
  bool _isMonthPaid(int month, int year) {
    return _payments.any(
        (p) => p.month == month && p.year == year && p.status == 'paid');
  }

  /// Toggle payment status
  Future<void> _togglePayment(int month, int year, bool currentlyPaid) async {
    if (currentlyPaid) {
      await _paymentService.markUnpaid(
        flatId: widget.flat.id,
        month: month,
        year: year,
      );
    } else {
      await _paymentService.markPaid(
        societyId: widget.societyId,
        flatId: widget.flat.id,
        month: month,
        year: year,
      );
    }
    await _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    // Calculate totals
    final dues = _paymentService.calculateDues(
      payments: _payments,
      amountHistory: widget.amountHistory,
      startMonth: widget.flat.createdAt.month,
      startYear: widget.flat.createdAt.year,
    );
    final totalDue = dues['totalDue'] as double;
    final unpaidMonths = dues['unpaidMonths'] as int;

    final now = DateTime.now();
    final months = <Map<String, int>>[];
    int currentMonth = widget.flat.createdAt.month;
    int currentYear = widget.flat.createdAt.year;

    while (currentYear < now.year ||
        (currentYear == now.year && currentMonth <= now.month)) {
      months.add({'month': currentMonth, 'year': currentYear});
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    final currentAmount =
        PaymentService.getCurrentAmount(widget.amountHistory);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flat ${widget.flat.flatNumber}'),
      ),
      body: Column(
        children: [
          // ─── Flat Info Header ────────────────────
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: totalDue > 0
                  ? AppTheme.dangerGradient
                  : AppTheme.successGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Flat icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.flat.ownerName,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '📞 ${widget.flat.phone}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${totalDue.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      totalDue > 0
                          ? '$unpaidMonths month${unpaidMonths > 1 ? 's' : ''} due'
                          : 'All clear ✅',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Monthly Payments',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${currentAmount.toStringAsFixed(0)}/month',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Month-wise Payment List ─────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final m = months[index]['month']!;
                final y = months[index]['year']!;
                final paid = _isMonthPaid(m, y);
                final monthAmount = PaymentService.getAmountForMonth(
                    widget.amountHistory, m, y);
                final monthNames = [
                  'January', 'February', 'March', 'April',
                  'May', 'June', 'July', 'August',
                  'September', 'October', 'November', 'December'
                ];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppTheme.darkCardDecoration(context),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: paid
                            ? AppTheme.paidColor.withOpacity(0.1)
                            : AppTheme.unpaidColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        paid
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        color: paid
                            ? AppTheme.paidColor
                            : AppTheme.unpaidColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      '${monthNames[m - 1]} $y',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '₹${monthAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () => _togglePayment(m, y, paid),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paid
                              ? AppTheme.unpaidColor.withOpacity(0.1)
                              : AppTheme.paidColor,
                          foregroundColor:
                              paid ? AppTheme.unpaidColor : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          paid ? 'Mark Unpaid' : 'Mark Paid',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
