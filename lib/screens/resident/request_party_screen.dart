import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/party_request_model.dart';
import '../../services/party_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Resident screen to request party/function and see status
class RequestPartyScreen extends StatefulWidget {
  final String societyId;
  final String userId;
  final String flatNumber;
  final String userName;

  const RequestPartyScreen({
    super.key,
    required this.societyId,
    required this.userId,
    required this.flatNumber,
    required this.userName,
  });

  @override
  State<RequestPartyScreen> createState() => _RequestPartyScreenState();
}

class _RequestPartyScreenState extends State<RequestPartyScreen> {
  final _partyService = PartyService();

  void _showRequestDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Request Party/Function',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Event Title',
                    icon: Icons.celebration_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Description',
                    icon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: AppTheme.inputDecoration(
                      context: context,
                      label: 'Date',
                      icon: Icons.calendar_today_rounded,
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeCtrl,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Time (e.g. 7:00 PM)',
                    icon: Icons.access_time_rounded,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final request = PartyRequestModel(
                  id: '',
                  societyId: widget.societyId,
                  userId: widget.userId,
                  flatNumber: widget.flatNumber,
                  userName: widget.userName,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  date: selectedDate,
                  time: timeCtrl.text.trim(),
                  status: 'pending',
                  createdAt: DateTime.now(),
                );
                await _partyService.submitRequest(request);
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request submitted!'),
                      backgroundColor: AppTheme.paidColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Submit', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Party / Function')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Request',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<PartyRequestModel>>(
        stream: _partyService.streamUserRequests(
            widget.societyId, widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(
                message: 'Loading requests...');
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.celebration_rounded,
              title: 'No requests yet',
              subtitle: 'Submit a party/function request',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              return _requestCard(r);
            },
          );
        },
      ),
    );
  }

  Widget _requestCard(PartyRequestModel r) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    if (r.isPending) {
      statusColor = AppTheme.warningColor;
      statusText = 'PENDING';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (r.isApproved) {
      statusColor = AppTheme.paidColor;
      statusText = 'APPROVED';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppTheme.unpaidColor;
      statusText = 'REJECTED';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.darkCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(r.date)} at ${r.time}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.description,
              style: GoogleFonts.poppins(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
