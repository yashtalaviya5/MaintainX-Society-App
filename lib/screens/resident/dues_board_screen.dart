import 'package:flutter/material.dart';
import '../../services/flat_service.dart';
import '../../services/payment_service.dart';
import '../../models/flat_model.dart';
import '../../models/payment_model.dart';
import '../../widgets/flat_due_card.dart';
import '../../widgets/loading_indicator.dart';
import 'flat_detail_screen.dart';

/// Dues board showing all flats with due status (read-only for residents)
class DuesBoardScreen extends StatefulWidget {
  final String societyId;

  const DuesBoardScreen({super.key, required this.societyId});

  @override
  State<DuesBoardScreen> createState() => _DuesBoardScreenState();
}

class _DuesBoardScreenState extends State<DuesBoardScreen> {
  final _flatService = FlatService();
  final _paymentService = PaymentService();
  List<Map<String, dynamic>> _amountHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final history =
        await PaymentService.loadAmountHistory(widget.societyId);
    setState(() {
      _amountHistory = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Dues Board')),
      body: StreamBuilder<List<FlatModel>>(
        stream: _flatService.streamFlats(widget.societyId),
        builder: (context, flatSnapshot) {
          if (flatSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading dues...');
          }

          final flats = flatSnapshot.data ?? [];
          if (flats.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long_rounded,
              title: 'No flats in this society',
              subtitle: 'Ask your admin to add flats',
            );
          }

          return FutureBuilder<List<PaymentModel>>(
            future: _paymentService.getPaymentsForSociety(widget.societyId),
            builder: (context, paySnapshot) {
              if (paySnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }

              final allPayments = paySnapshot.data ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: flats.length,
                itemBuilder: (context, index) {
                  final flat = flats[index];
                  final flatPayments = allPayments
                      .where((p) => p.flatId == flat.id)
                      .toList();
                  final dues = _paymentService.calculateDues(
                    payments: flatPayments,
                    amountHistory: _amountHistory,
                    startMonth: flat.createdAt.month,
                    startYear: flat.createdAt.year,
                  );

                  return FlatDueCard(
                    flatNumber: flat.flatNumber,
                    ownerName: flat.ownerName,
                    unpaidMonths: dues['unpaidMonths'] as int,
                    totalDue: dues['totalDue'] as double,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlatDetailScreen(
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
    );
  }
}
