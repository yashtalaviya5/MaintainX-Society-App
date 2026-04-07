import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/society_service.dart';
import '../../models/society_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/loading_indicator.dart';

/// Society details screen with copy-to-clipboard Society ID
class SocietyDetailsScreen extends StatelessWidget {
  final String societyId;
  final _societyService = SocietyService();

  SocietyDetailsScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Details')),
      body: FutureBuilder<SocietyModel?>(
        future: _societyService.getSociety(societyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final society = snapshot.data;
          if (society == null) {
            return const Center(child: Text('Society not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Society Name Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        society.societyName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        society.city,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info Cards
                _infoCard(
                  context: context,
                  icon: Icons.location_city_rounded,
                  title: 'City',
                  value: society.city,
                ),
                _infoCard(
                  context: context,
                  icon: Icons.place_outlined,
                  title: 'Address',
                  value: society.address,
                ),

                // Society ID Card with copy
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: AppTheme.darkCardDecoration(context),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: AppTheme.accentColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Society ID',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.contrastSecondary(context),
                      ),
                    ),
                    subtitle: Text(
                      societyId,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.contrastText(context),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppTheme.accentColor),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: societyId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Society ID copied! 📋'),
                            backgroundColor: AppTheme.paidColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Share this Society ID with residents so they can join your society.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.darkCardDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.contrastSecondary(context),
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.contrastText(context),
          ),
        ),
      ),
    );
  }
}
