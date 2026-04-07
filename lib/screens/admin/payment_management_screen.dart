import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/flat_service.dart';
import '../../services/payment_service.dart';
import '../../models/flat_model.dart';
import '../../models/payment_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/flat_due_card.dart';
import '../../widgets/loading_indicator.dart';
import 'flat_payment_details_screen.dart';

/// Admin screen showing all flats with their payment overview
class PaymentManagementScreen extends StatefulWidget {
  final String societyId;

  const PaymentManagementScreen({super.key, required this.societyId});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final _flatService = FlatService();
  final _paymentService = PaymentService();

  String _filter = 'All'; // All, Paid, Unpaid
  bool _sortHighestFirst = false;
  List<Map<String, dynamic>> _amountHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAmountHistory();
  }

  Future<void> _loadAmountHistory() async {
    final history =
        await PaymentService.loadAmountHistory(widget.societyId);
    setState(() {
      _amountHistory = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        actions: [
          // Sort button
          IconButton(
            icon: Icon(
              _sortHighestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.sort_rounded,
              size: 22,
            ),
            tooltip: 'Sort by highest due',
            onPressed: () =>
                setState(() => _sortHighestFirst = !_sortHighestFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter Chips ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: ['All', 'Paid', 'Unpaid'].map((label) {
                final selected = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.contrastSecondary(context),
                    ),
                    onSelected: (_) => setState(() => _filter = label),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Flat List ────────────────────────────
          Expanded(
            child: StreamBuilder<List<FlatModel>>(
              stream: _flatService.streamFlats(widget.societyId),
              builder: (context, flatSnapshot) {
                if (flatSnapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(
                      message: 'Loading flats...');
                }

                final flats = flatSnapshot.data ?? [];
                if (flats.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.home_work_rounded,
                    title: 'No flats added',
                    subtitle: 'Add flats from Flat Management first',
                  );
                }

                return FutureBuilder<List<PaymentModel>>(
                  future: _paymentService
                      .getPaymentsForSociety(widget.societyId),
                  builder: (context, paySnapshot) {
                    if (paySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LoadingIndicator();
                    }

                    final allPayments = paySnapshot.data ?? [];

                    // Calculate dues for each flat
                    var flatDues = flats.map((flat) {
                      final flatPayments = allPayments
                          .where((p) => p.flatId == flat.id)
                          .toList();
                      final dues = _paymentService.calculateDues(
                        payments: flatPayments,
                        amountHistory: _amountHistory,
                        startMonth: flat.createdAt.month,
                        startYear: flat.createdAt.year,
                      );
                      return {
                        'flat': flat,
                        'totalDue': dues['totalDue'] as double,
                        'unpaidMonths': dues['unpaidMonths'] as int,
                        'paidMonths': dues['paidMonths'] as int,
                      };
                    }).toList();

                    // Apply filter
                    if (_filter == 'Paid') {
                      flatDues = flatDues
                          .where((d) => (d['totalDue'] as double) == 0)
                          .toList();
                    } else if (_filter == 'Unpaid') {
                      flatDues = flatDues
                          .where((d) => (d['totalDue'] as double) > 0)
                          .toList();
                    }

                    // Apply sort
                    if (_sortHighestFirst) {
                      flatDues.sort((a, b) => (b['totalDue'] as double)
                          .compareTo(a['totalDue'] as double));
                    }

                    if (flatDues.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.check_circle_rounded,
                        title: _filter == 'Paid'
                            ? 'No fully paid flats'
                            : 'No unpaid flats',
                        subtitle: 'All clear!',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: flatDues.length,
                      itemBuilder: (context, index) {
                        final data = flatDues[index];
                        final flat = data['flat'] as FlatModel;
                        return FlatDueCard(
                          flatNumber: flat.flatNumber,
                          ownerName: flat.ownerName,
                          unpaidMonths: data['unpaidMonths'] as int,
                          totalDue: data['totalDue'] as double,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FlatPaymentDetailsScreen(
                                  flat: flat,
                                  societyId: widget.societyId,
                                  amountHistory: _amountHistory,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
