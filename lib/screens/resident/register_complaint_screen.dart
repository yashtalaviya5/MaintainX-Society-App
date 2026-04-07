import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

/// Register complaint screen for residents
class RegisterComplaintScreen extends StatefulWidget {
  final String societyId;
  final String userId;

  const RegisterComplaintScreen({
    super.key,
    required this.societyId,
    required this.userId,
  });

  @override
  State<RegisterComplaintScreen> createState() =>
      _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends State<RegisterComplaintScreen> {
  final _complaintService = ComplaintService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _complaintService.addComplaint(ComplaintModel(
        id: '',
        societyId: widget.societyId,
        flatId: '',
        userId: widget.userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: 'open',
        createdAt: DateTime.now(),
      ));

      _titleController.clear();
      _descController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully! ✅'),
            backgroundColor: AppTheme.paidColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.unpaidColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── New Complaint Form ──────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.elevatedCardDecoration(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.unpaidColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.report_rounded,
                            color: AppTheme.unpaidColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Register New Complaint',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.contrastText(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: AppTheme.inputDecoration(
                      context: context,
                      label: 'Complaint Title',
                      icon: Icons.title_rounded,
                      hint: 'e.g. Water leakage in lobby',
                    ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      decoration: AppTheme.inputDecoration(
                      context: context,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      hint: 'Describe the issue in detail...',
                    ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitComplaint,
                        style: AppTheme.primaryButtonStyle,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit Complaint',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── My Complaints List ──────────────
            Text(
              'My Complaints',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.contrastText(context),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<ComplaintModel>>(
              stream: _complaintService.streamUserComplaints(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: LoadingIndicator(),
                  );
                }

                final complaints = snapshot.data ?? [];
                if (complaints.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sentiment_satisfied_rounded,
                          size: 48,
                          color: AppTheme.paidColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No complaints filed',
                          style: GoogleFonts.poppins(
                            color: AppTheme.contrastSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final c = complaints[index];
                    final dateStr =
                        DateFormat('dd MMM yyyy').format(c.createdAt);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      decoration: AppTheme.darkCardDecoration(context),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.contrastText(context),
                                    ),
                                  ),
                                ),
                                StatusBadge(
                                  label: c.status.toUpperCase(),
                                  color: _statusColor(c.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.contrastSecondary(context),
                                ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.contrastSecondary(context).withOpacity(0.7),
                                ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
