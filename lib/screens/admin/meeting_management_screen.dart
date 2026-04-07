import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/meeting_model.dart';
import '../../services/meeting_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Admin screen to schedule and manage society meetings
class MeetingManagementScreen extends StatefulWidget {
  final String societyId;
  final String senderId;

  const MeetingManagementScreen({
    super.key,
    required this.societyId,
    required this.senderId,
  });

  @override
  State<MeetingManagementScreen> createState() =>
      _MeetingManagementScreenState();
}

class _MeetingManagementScreenState extends State<MeetingManagementScreen> {
  final _meetingService = MeetingService();

  void _showScheduleDialog() {
    final titleCtrl = TextEditingController();
    final agendaCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Schedule Meeting',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Meeting Title',
                    icon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: agendaCtrl,
                  maxLines: 3,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Agenda/Description',
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
                    label: 'Time (e.g. 10:00 AM)',
                    icon: Icons.access_time_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationCtrl,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Location',
                    icon: Icons.place_rounded,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: AppTheme.contrastSecondary(context))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final meeting = MeetingModel(
                  id: '',
                  societyId: widget.societyId,
                  title: titleCtrl.text.trim(),
                  agenda: agendaCtrl.text.trim(),
                  date: selectedDate,
                  time: timeCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                await _meetingService.scheduleMeeting(meeting, widget.senderId);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Schedule', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text('Schedule',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<MeetingModel>>(
        stream: _meetingService.streamMeetings(widget.societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading meetings...');
          }
          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.groups_rounded,
              title: 'No meetings scheduled',
              subtitle: 'Schedule your first meeting',
            );
          }

          final upcoming = meetings.where((m) => m.isUpcoming).toList();
          final past = meetings.where((m) => !m.isUpcoming).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming Meetings'),
                ...upcoming.map((m) => _meetingCard(m, isUpcoming: true)),
                const SizedBox(height: 20),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Past Meetings'),
                ...past.map((m) => _meetingCard(m, isUpcoming: false)),
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

  Widget _meetingCard(MeetingModel meeting, {required bool isUpcoming}) {
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
                        color: AppTheme.contrastText(context),
                      ),
                    ),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(meeting.date)} • ${meeting.time}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.contrastSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isUpcoming)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.unpaidColor, size: 20),
                  onPressed: () =>
                      _meetingService.deleteMeeting(meeting.id),
                ),
            ],
          ),
          if (meeting.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  meeting.location,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.contrastSecondary(context),
                  ),
                ),
              ],
            ),
          ],
          if (meeting.agenda.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meeting.agenda,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.contrastSecondary(context),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
