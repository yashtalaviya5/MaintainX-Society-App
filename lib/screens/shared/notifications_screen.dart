import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Shared notification list screen
class NotificationsScreen extends StatelessWidget {
  final String societyId;
  final String userId;

  const NotificationsScreen({
    super.key,
    required this.societyId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                notificationService.markAllRead(societyId, userId),
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.streamNotifications(societyId, userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(
                message: 'Loading notifications...');
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _notificationTile(context, n, notificationService);
            },
          );
        },
      ),
    );
  }

  Widget _notificationTile(BuildContext context, NotificationModel n,
      NotificationService service) {
    IconData icon;
    Color color;
    switch (n.type) {
      case 'event':
        icon = Icons.event_rounded;
        color = AppTheme.primaryColor;
        break;
      case 'meeting':
        icon = Icons.groups_rounded;
        color = AppTheme.accentColor;
        break;
      case 'notice':
        icon = Icons.campaign_rounded;
        color = AppTheme.warningColor;
        break;
      case 'complaint':
        icon = Icons.report_rounded;
        color = AppTheme.unpaidColor;
        break;
      case 'party':
        icon = Icons.celebration_rounded;
        color = const Color(0xFF7E57C2);
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: () {
        if (!n.isRead) service.markRead(n.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead
              ? Theme.of(context).cardColor
              : AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: n.isRead
              ? null
              : Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                          n.isRead ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                  if (n.body.isNotEmpty)
                    Text(
                      n.body,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(n.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dateTime);
  }
}
