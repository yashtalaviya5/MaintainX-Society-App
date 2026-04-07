import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/flat_service.dart';
import '../../models/flat_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Flat management screen with add/edit/delete functionality
class FlatManagementScreen extends StatefulWidget {
  final String societyId;

  const FlatManagementScreen({super.key, required this.societyId});

  @override
  State<FlatManagementScreen> createState() => _FlatManagementScreenState();
}

class _FlatManagementScreenState extends State<FlatManagementScreen> {
  final _flatService = FlatService();

  void _showFlatDialog({FlatModel? flat}) {
    final flatNumController = TextEditingController(
      text: flat?.flatNumber ?? '',
    );
    final ownerController = TextEditingController(text: flat?.ownerName ?? '');
    final phoneController = TextEditingController(text: flat?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          flat == null ? 'Add New Flat' : 'Edit Flat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: flatNumController,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Flat Number',
                    icon: Icons.home_work_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ownerController,
                  textCapitalization: TextCapitalization.words,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Owner Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: AppTheme.inputDecoration(
                    context: context,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
              style: GoogleFonts.poppins(color: AppTheme.contrastSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final newFlat = FlatModel(
                id: flat?.id ?? '',
                societyId: widget.societyId,
                flatNumber: flatNumController.text.trim(),
                ownerName: ownerController.text.trim(),
                phone: phoneController.text.trim(),
                createdAt: flat?.createdAt ?? DateTime.now(),
              );

              if (flat == null) {
                await _flatService.addFlat(newFlat);
              } else {
                await _flatService.updateFlat(newFlat);
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: AppTheme.primaryButtonStyle,
            child: Text(flat == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(FlatModel flat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Flat ${flat.flatNumber}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will also delete all payment records for this flat. This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.contrastSecondary(context),
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.contrastSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _flatService.deleteFlat(flat.id);
              if (ctx.mounted) Navigator.pop(ctx);
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
      appBar: AppBar(title: const Text('Flat Management')),
      body: StreamBuilder<List<FlatModel>>(
        stream: _flatService.streamFlats(widget.societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading flats...');
          }

          final flats = snapshot.data ?? [];

          if (flats.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.apartment_rounded,
              title: 'No flats added yet',
              subtitle: 'Tap the + button to add your first flat',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                decoration: AppTheme.darkCardDecoration(context),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        flat.flatNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  title: Text(
                    flat.ownerName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.contrastText(context),
                    ),
                  ),
                  subtitle: Text(
                    '📞 ${flat.phone}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.contrastSecondary(context),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        onPressed: () => _showFlatDialog(flat: flat),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.unpaidColor,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(flat),
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
        onPressed: () => _showFlatDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Flat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
