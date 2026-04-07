import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';
import '../../services/payment_service.dart';

/// Maintenance settings screen — allows admin to set monthly amount
class MaintenanceSettingsScreen extends StatefulWidget {
  final String societyId;

  const MaintenanceSettingsScreen({super.key, required this.societyId});

  @override
  State<MaintenanceSettingsScreen> createState() =>
      _MaintenanceSettingsScreenState();
}

class _MaintenanceSettingsScreenState extends State<MaintenanceSettingsScreen> {
  final _amountController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  double _currentAmount = 0;
  List<Map<String, dynamic>> _amountHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _amountHistory =
        await PaymentService.loadAmountHistory(widget.societyId);
    _currentAmount = PaymentService.getCurrentAmount(_amountHistory);
    _amountController.text = _currentAmount.toStringAsFixed(0);
    setState(() => _isLoading = false);
  }

  Future<void> _saveAmount() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppTheme.unpaidColor,
        ),
      );
      return;
    }

    // If same as current amount, no need to add a new history entry
    if (amount == _currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount is already set to this value'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // New rate is effective from the next month
      final now = DateTime.now();
      int effMonth = now.month + 1;
      int effYear = now.year;
      if (effMonth > 12) {
        effMonth = 1;
        effYear++;
      }

      final newEntry = {
        'amount': amount,
        'effectiveMonth': effMonth,
        'effectiveYear': effYear,
      };

      // Add to history (keep existing entries, append new one)
      final updatedHistory = List<Map<String, dynamic>>.from(_amountHistory);
      
      // Remove any existing entry for the same month/year (replace it)
      updatedHistory.removeWhere((e) =>
          e['effectiveMonth'] == now.month && e['effectiveYear'] == now.year);
      updatedHistory.add(newEntry);

      await _firestore
          .collection('maintenance_settings')
          .doc(widget.societyId)
          .set({
        'amount': amount, // keep legacy field for current amount
        'societyId': widget.societyId,
        'amountHistory': updatedHistory,
      });

      setState(() {
        _currentAmount = amount;
        _amountHistory = updatedHistory;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance amount updated! ✅'),
            backgroundColor: AppTheme.paidColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.unpaidColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current amount display
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Monthly Maintenance',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_currentAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'per flat / month',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Edit section
            Text(
              'Update Amount',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.contrastText(context),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: AppTheme.inputDecoration(
                context: context,
                label: 'Monthly Amount (₹)',
                icon: Icons.currency_rupee_rounded,
                hint: 'e.g. 2000',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAmount,
                style: AppTheme.primaryButtonStyle,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New amount applies from the next month onward. Previous months (including the current month) keep their original rate.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Amount History Section
            if (_amountHistory.length > 1) ...[
              const SizedBox(height: 28),
              Text(
                'Rate Change History',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.contrastText(context),
                ),
              ),
              const SizedBox(height: 12),
              ..._amountHistory.reversed.map((entry) {
                final monthNames = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                final m = entry['effectiveMonth'] as int;
                final y = entry['effectiveYear'] as int;
                final amt = (entry['amount'] ?? 0).toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.darkCardDecoration(context),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'From ${monthNames[m - 1]} $y',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.contrastSecondary(context),
                          ),
                        ),
                      ),
                      Text(
                        '₹${amt.toStringAsFixed(0)}/month',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.contrastText(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
