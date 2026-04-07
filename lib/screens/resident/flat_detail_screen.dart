import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/payment_service.dart';
import '../../models/flat_model.dart';
import '../../models/payment_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';

/// Flat detail screen for residents (read-only month-wise payments)
class FlatDetailScreen extends StatefulWidget {
  final FlatModel flat;
  final String societyId;
  final List<Map<String, dynamic>> amountHistory;

  const FlatDetailScreen({
    super.key,
    required this.flat,
    required this.societyId,
    required this.amountHistory,
  });

  @override
  State<FlatDetailScreen> createState() => _FlatDetailScreenState();
}

class _FlatDetailScreenState extends State<FlatDetailScreen> {
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

  bool _isMonthPaid(int month, int year) {
    return _payments.any(
        (p) => p.month == month && p.year == year && p.status == 'paid');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

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

    final monthNames = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Flat ${widget.flat.flatNumber}')),
      body: Column(
        children: [
          // Flat info header
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
                        'Flat ${widget.flat.flatNumber}',
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

          // Monthly list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Payment History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Month-wise list (read-only)
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
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
                      ),
                    ),
                    subtitle: Text(
                      '₹${monthAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: StatusBadge(
                      label: paid ? 'PAID' : 'UNPAID',
                      color: paid ? AppTheme.paidColor : AppTheme.unpaidColor,
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
