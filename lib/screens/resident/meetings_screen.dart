import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/meeting_model.dart';
import '../../services/meeting_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Resident screen to view society meetings
class MeetingsScreen extends StatelessWidget {
  final String societyId;

  const MeetingsScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    final meetingService = MeetingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: StreamBuilder<List<MeetingModel>>(
        stream: meetingService.streamMeetings(societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading meetings...');
          }
          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.groups_rounded,
              title: 'No meetings scheduled',
              subtitle: 'Upcoming meetings will appear here',
            );
          }

          final upcoming = meetings.where((m) => m.isUpcoming).toList();
          final past = meetings.where((m) => !m.isUpcoming).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming Meetings'),
                ...upcoming.map((m) => _meetingCard(context, m, true)),
                const SizedBox(height: 20),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Past Meetings'),
                ...past.map((m) => _meetingCard(context, m, false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _meetingCard(
      BuildContext context, MeetingModel meeting, bool isUpcoming) {
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isUpcoming
                      ? AppTheme.accentGradient
                      : const LinearGradient(
                          colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(meeting.date)} • ${meeting.time}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUpcoming)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.paidColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'UPCOMING',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.paidColor,
                    ),
                  ),
                ),
            ],
          ),
          if (meeting.location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  meeting.location,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (meeting.agenda.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meeting.agenda,
              style: GoogleFonts.poppins(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
