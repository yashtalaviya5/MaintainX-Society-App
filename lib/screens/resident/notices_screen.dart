import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/notice_service.dart';
import '../../models/notice_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Notices screen for residents (read-only)
class NoticesScreen extends StatelessWidget {
  final String societyId;
  final _noticeService = NoticeService();

  NoticesScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: StreamBuilder<List<NoticeModel>>(
        stream: _noticeService.streamNotices(societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading notices...');
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.campaign_rounded,
              title: 'No notices yet',
              subtitle: 'Check back later for updates from your admin',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final dateStr =
                  DateFormat('dd MMM yyyy, hh:mm a').format(notice.createdAt);
              final isRecent = DateTime.now()
                      .difference(notice.createdAt)
                      .inDays < 3;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                clipBehavior: Clip.antiAlias,
                decoration: AppTheme.darkCardDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notice.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.contrastText(context),
                              ),
                            ),
                          ),
                          if (isRecent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.unpaidColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.unpaidColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notice.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.contrastSecondary(context),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.contrastSecondary(context).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
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
