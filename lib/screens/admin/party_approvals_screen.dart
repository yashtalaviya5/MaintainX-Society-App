import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/party_request_model.dart';
import '../../services/party_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Admin screen to approve/reject party requests
class PartyApprovalsScreen extends StatefulWidget {
  final String societyId;
  final String senderId;

  const PartyApprovalsScreen({
    super.key,
    required this.societyId,
    required this.senderId,
  });

  @override
  State<PartyApprovalsScreen> createState() => _PartyApprovalsScreenState();
}

class _PartyApprovalsScreenState extends State<PartyApprovalsScreen> {
  final _partyService = PartyService();

  Future<void> _approve(PartyRequestModel request) async {
    await _partyService.approveRequest(request, widget.senderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved')),
      );
    }
  }

  Future<void> _reject(PartyRequestModel request) async {
    await _partyService.rejectRequest(request, widget.senderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Party Approvals')),
      body: StreamBuilder<List<PartyRequestModel>>(
        stream: _partyService.streamRequests(widget.societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading requests...');
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.celebration_rounded,
              title: 'No party requests',
              subtitle: 'Requests from residents will appear here',
            );
          }

          final pending = requests.where((r) => r.isPending).toList();
          final handled = requests.where((r) => !r.isPending).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader('Pending Requests', pending.length),
                ...pending.map((r) => _requestCard(r)),
                const SizedBox(height: 20),
              ],
              if (handled.isNotEmpty) ...[
                _sectionHeader('Handled Requests', handled.length),
                ...handled.map((r) => _requestCard(r)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.contrastText(context),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(PartyRequestModel request) {
    Color statusColor;
    String statusText;
    if (request.isPending) {
      statusColor = AppTheme.warningColor;
      statusText = 'PENDING';
    } else if (request.isApproved) {
      statusColor = AppTheme.paidColor;
      statusText = 'APPROVED';
    } else {
      statusColor = AppTheme.unpaidColor;
      statusText = 'REJECTED';
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.celebration_rounded,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.contrastText(context),
                      ),
                    ),
                    Text(
                      'Flat ${request.flatNumber} • ${request.userName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.contrastSecondary(context),
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
          const SizedBox(height: 10),
          Text(
            '${DateFormat('dd MMM yyyy').format(request.date)} at ${request.time}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.contrastSecondary(context),
            ),
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.contrastSecondary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.unpaidColor,
                      side: const BorderSide(color: AppTheme.unpaidColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Reject',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approve(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.paidColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Approve',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
