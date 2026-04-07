import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/notice_service.dart';
import '../../models/notice_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Notice management screen for admin (CRUD)
class NoticeManagementScreen extends StatefulWidget {
  final String societyId;
  final String senderId;

  const NoticeManagementScreen({
    super.key,
    required this.societyId,
    required this.senderId,
  });

  @override
  State<NoticeManagementScreen> createState() => _NoticeManagementScreenState();
}

class _NoticeManagementScreenState extends State<NoticeManagementScreen> {
  final _noticeService = NoticeService();

  void _showNoticeDialog({NoticeModel? notice}) {
    final titleController = TextEditingController(text: notice?.title ?? '');
    final descController = TextEditingController(
      text: notice?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          notice == null ? 'Create Notice' : 'Edit Notice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Notice Title',
                    icon: Icons.title_rounded,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Content',
                    icon: Icons.description_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Description is required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              if (notice == null) {
                // Create new
                await _noticeService.addNotice(
                  NoticeModel(
                    id: '',
                    societyId: widget.societyId,
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                  widget.senderId,
                );
              } else {
                // Update existing
                await _noticeService.updateNotice(
                  notice.id,
                  titleController.text.trim(),
                  descController.text.trim(),
                );
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: AppTheme.primaryButtonStyle,
            child: Text(notice == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Notice?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${notice.title}"?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _noticeService.deleteNotice(notice.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.unpaidColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: StreamBuilder<List<NoticeModel>>(
        stream: _noticeService.streamNotices(widget.societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading notices...');
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.campaign_rounded,
              title: 'No notices yet',
              subtitle: 'Tap the + button to create your first notice',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final dateStr = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(notice.createdAt);

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
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showNoticeDialog(notice: notice);
                              } else {
                                _confirmDelete(notice);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.contrastSecondary(context),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '📅 $dateStr',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoticeDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Notice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
