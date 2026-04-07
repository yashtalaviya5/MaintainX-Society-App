import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Resident screen to view society events
class EventsScreen extends StatelessWidget {
  final String societyId;

  const EventsScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: StreamBuilder<List<EventModel>>(
        stream: eventService.streamEvents(societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading events...');
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event_rounded,
              title: 'No events yet',
              subtitle: 'Society events will appear here',
            );
          }

          final upcoming = events.where((e) => e.isUpcoming).toList();
          final past = events.where((e) => !e.isUpcoming).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _sectionHeader('Upcoming Events'),
                ...upcoming.map((e) => _eventCard(context, e, true)),
                const SizedBox(height: 20),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Past Events'),
                ...past.map((e) => _eventCard(context, e, false)),
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

  Widget _eventCard(BuildContext context, EventModel event, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.darkCardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: isUpcoming
                  ? AppTheme.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(event.date),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.time.isNotEmpty)
                  Text(
                    event.time,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: GoogleFonts.poppins(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
