import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';

/// Complaint management screen for admin
class ComplaintManagementScreen extends StatelessWidget {
  final String societyId;
  final _complaintService = ComplaintService();

  ComplaintManagementScreen({super.key, required this.societyId});

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppTheme.unpaidColor;
      case 'in-progress':
        return AppTheme.warningColor;
      case 'resolved':
        return AppTheme.paidColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.error_outline_rounded;
      case 'in-progress':
        return Icons.autorenew_rounded;
      case 'resolved':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _changeStatus(BuildContext context, ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _statusOption(ctx, complaint.id, 'open', 'Open'),
            _statusOption(ctx, complaint.id, 'in-progress', 'In Progress'),
            _statusOption(ctx, complaint.id, 'resolved', 'Resolved'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(
      BuildContext ctx, String complaintId, String status, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          _complaintService.updateStatus(complaintId, status);
          Navigator.pop(ctx);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: _statusColor(status).withOpacity(0.08),
        leading: Icon(_statusIcon(status), color: _statusColor(status)),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _statusColor(status),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _complaintService.streamComplaints(societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading complaints...');
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.sentiment_satisfied_rounded,
              title: 'No complaints',
              subtitle: 'All is well in your society!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final dateStr =
                  DateFormat('dd MMM yyyy').format(complaint.createdAt);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                decoration: AppTheme.darkCardDecoration(context),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _changeStatus(context, complaint),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _statusColor(complaint.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _statusIcon(complaint.status),
                                color: _statusColor(complaint.status),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                complaint.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.contrastText(context),
                                ),
                              ),
                            ),
                            StatusBadge(
                              label: complaint.status.toUpperCase(),
                              color: _statusColor(complaint.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          complaint.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.contrastSecondary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '📅 $dateStr',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.contrastSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
