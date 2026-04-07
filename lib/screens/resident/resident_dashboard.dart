import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/society_service.dart';
import '../../services/notification_service.dart';
import '../../services/flat_service.dart';
import '../../models/user_model.dart';
import '../../models/society_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_indicator.dart';
import '../auth/login_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/notifications_screen.dart';
import 'dues_board_screen.dart';
import 'register_complaint_screen.dart';
import 'notices_screen.dart';
import 'events_screen.dart';
import 'meetings_screen.dart';
import 'request_party_screen.dart';

/// Resident Dashboard with quick actions, drawer, and notifications
class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  final _authService = AuthService();
  final _societyService = SocietyService();
  final _flatService = FlatService();
  final _notificationService = NotificationService();

  UserModel? _currentUser;
  SocietyModel? _society;
  String? _flatNumber;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user == null) return;
      _currentUser = user;

      // Start listening for notifications
      NotificationService.instance.listenForNewNotifications(
        societyId: user.societyId,
        userId: user.id,
        userRole: user.role,
      );

      _society = await _societyService.getSociety(user.societyId);

      // Try to find the resident's flat by name match
      final flats = await _flatService.getFlats(user.societyId);
      final myFlat = flats.where((f) =>
          f.ownerName.toLowerCase() == user.name.toLowerCase());
      if (myFlat.isNotEmpty) _flatNumber = myFlat.first.flatNumber;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading...'),
      );
    }

    final pages = [
      _buildHomePage(),
      DuesBoardScreen(societyId: _currentUser?.societyId ?? ''),
      RegisterComplaintScreen(
        societyId: _currentUser?.societyId ?? '',
        userId: _currentUser?.id ?? '',
      ),
      NoticesScreen(societyId: _currentUser?.societyId ?? ''),
      const ProfileScreen(),
    ];

    return Scaffold(
      drawer: _buildDrawer(),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Dues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_rounded),
              label: 'Complaint',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_rounded),
              label: 'Notices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (_currentUser?.name ?? 'R')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentUser?.name ?? 'Resident',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_flatNumber != null)
                  Text(
                    'Flat $_flatNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.event_rounded, 'Events', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventsScreen(
                          societyId: _currentUser!.societyId),
                    ),
                  );
                }),
                _drawerItem(Icons.groups_rounded, 'Meetings', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeetingsScreen(
                          societyId: _currentUser!.societyId),
                    ),
                  );
                }),
                _drawerItem(
                    Icons.celebration_rounded, 'Party / Function', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestPartyScreen(
                        societyId: _currentUser!.societyId,
                        userId: _currentUser!.id,
                        flatNumber: _flatNumber ?? '',
                        userName: _currentUser!.name,
                      ),
                    ),
                  );
                }),
                const Divider(),
                _drawerItem(Icons.logout_rounded, 'Logout', _logout,
                    color: AppTheme.unpaidColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primaryColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────
            Row(
              children: [
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_rounded,
                          color: AppTheme.primaryColor, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _currentUser?.name ?? 'Resident',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Notification bell
                _buildNotificationBell(),
              ],
            ),
            const SizedBox(height: 12),

            if (_society != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: AppTheme.glassDecoration(context).copyWith(
                    color: AppTheme.accentColor.withOpacity(0.1),
                  ),
                  child: Text(
                    '🏢 ${_society!.societyName}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 28),

            // ─── Quick Actions Grid ──────────────
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: [
                PremiumCard(
                  title: 'View Dues',
                  value: 'Current Dues',
                  icon: Icons.receipt_long_rounded,
                  gradient: AppTheme.primaryGradient,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                PremiumCard(
                  title: 'File Complaint',
                  value: 'Support',
                  icon: Icons.report_rounded,
                  gradient: AppTheme.dangerGradient,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                PremiumCard(
                  title: 'Events',
                  value: 'Explore',
                  icon: Icons.event_rounded,
                  gradient: AppTheme.accentGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventsScreen(
                          societyId: _currentUser!.societyId),
                    ),
                  ),
                ),
                PremiumCard(
                  title: 'Meetings',
                  value: 'Schedule',
                  icon: Icons.groups_rounded,
                  gradient: AppTheme.purpleGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeetingsScreen(
                          societyId: _currentUser!.societyId),
                    ),
                  ),
                ),
                PremiumCard(
                  title: 'Party Request',
                  value: 'Celebration',
                  icon: Icons.celebration_rounded,
                  gradient: AppTheme.amberGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestPartyScreen(
                        societyId: _currentUser!.societyId,
                        userId: _currentUser!.id,
                        flatNumber: _flatNumber ?? '',
                        userName: _currentUser!.name,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── Society Info Card ───────────────
            if (_society != null) ...[
              Text(
                'Your Society',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                clipBehavior: Clip.antiAlias,
                decoration: AppTheme.darkCardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _society!.societyName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_society!.city} • ${_society!.address}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return StreamBuilder<int>(
      stream: _notificationService.streamUnreadCount(
        _currentUser?.societyId ?? '',
        _currentUser?.id ?? '',
      ),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(
                societyId: _currentUser!.societyId,
                userId: _currentUser!.id,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppTheme.primaryColor, size: 22),
                if (count > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.unpaidColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
