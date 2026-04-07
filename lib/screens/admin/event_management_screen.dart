import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Admin screen to create and manage events
class EventManagementScreen extends StatefulWidget {
  final String societyId;
  final String senderId;

  const EventManagementScreen({
    super.key,
    required this.societyId,
    required this.senderId,
  });

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final _eventService = EventService();

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Create Event',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Event Title',
                    icon: Icons.title_rounded,
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
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    label: 'Time (e.g. 6:00 PM)',
                    icon: Icons.access_time_rounded,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppTheme.contrastSecondary(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final event = EventModel(
                  id: '',
                  societyId: widget.societyId,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  date: selectedDate,
                  time: timeCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                await _eventService.createEvent(event, widget.senderId);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Create', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.streamEvents(widget.societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading events...');
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event_rounded,
              title: 'No events yet',
              subtitle: 'Create your first event',
            );
          }

          final upcoming = events.where((e) => e.isUpcoming).toList();
          final past = events.where((e) => !e.isUpcoming).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming Events'),
                ...upcoming.map((e) => _eventCard(e, isUpcoming: true)),
                const SizedBox(height: 20),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Past Events'),
                ...past.map((e) => _eventCard(e, isUpcoming: false)),
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
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _eventCard(EventModel event, {required bool isUpcoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.darkCardDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isUpcoming
                ? AppTheme.primaryGradient
                : const LinearGradient(
                    colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('dd').format(event.date),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('MMM').format(event.date),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          event.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.contrastText(context),
          ),
        ),
        subtitle: Text(
          '${event.time}${event.description.isNotEmpty ? ' • ${event.description}' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.contrastSecondary(context),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isUpcoming
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.unpaidColor,
                  size: 20,
                ),
                onPressed: () => _eventService.deleteEvent(event.id),
              )
            : null,
      ),
    );
  }
}
