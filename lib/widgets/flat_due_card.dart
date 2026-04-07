import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'status_badge.dart';

/// Reusable card showing flat info with due amount and status
class FlatDueCard extends StatelessWidget {
  final String flatNumber;
  final String ownerName;
  final int unpaidMonths;
  final double totalDue;
  final VoidCallback? onTap;

  const FlatDueCard({
    super.key,
    required this.flatNumber,
    required this.ownerName,
    required this.unpaidMonths,
    required this.totalDue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPaid = totalDue == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.darkCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Flat number badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppTheme.paidColor.withOpacity(0.1)
                      : AppTheme.unpaidColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    flatNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPaid ? AppTheme.paidColor : AppTheme.unpaidColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.contrastText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaid
                          ? 'All dues cleared'
                          : '$unpaidMonths month${unpaidMonths > 1 ? 's' : ''} pending',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.contrastSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Status & Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: isPaid ? 'PAID' : '₹${totalDue.toStringAsFixed(0)}',
                    color: isPaid ? AppTheme.paidColor : AppTheme.unpaidColor,
                  ),
                  if (!isPaid) ...[
                    const SizedBox(height: 4),
                    Text(
                      'DUE',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.unpaidColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
