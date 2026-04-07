import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/society_service.dart';
import '../../services/flat_service.dart';
import '../../services/payment_service.dart';
import '../../services/complaint_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../models/society_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/loading_indicator.dart';
import '../auth/login_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/notifications_screen.dart';
import 'society_details_screen.dart';
import 'flat_management_screen.dart';
import 'payment_management_screen.dart';
import 'complaint_management_screen.dart';
import 'notice_management_screen.dart';
import 'maintenance_settings_screen.dart';
import 'event_management_screen.dart';
import 'meeting_management_screen.dart';
import 'party_approvals_screen.dart';

/// Admin Dashboard with stat cards, drawer, and notification bell
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _societyService = SocietyService();
  final _flatService = FlatService();
  final _paymentService = PaymentService();
  final _complaintService = ComplaintService();
  final _notificationService = NotificationService();

  UserModel? _currentUser;
  SocietyModel? _society;
  bool _isLoading = true;

  int _totalFlats = 0;
  double _totalPending = 0;
  int _unpaidFlats = 0;
  int _openComplaints = 0;
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

      final flats = await _flatService.getFlats(user.societyId);
      final allPayments =
          await _paymentService.getPaymentsForSociety(user.societyId);
      final complaints =
          await _complaintService.getComplaints(user.societyId);

      // Get maintenance amount history
      final amountHistory =
          await PaymentService.loadAmountHistory(user.societyId);

      double totalPending = 0;
      int unpaidCount = 0;

      for (final flat in flats) {
        final flatPayments =
            allPayments.where((p) => p.flatId == flat.id).toList();
        final dues = _paymentService.calculateDues(
          payments: flatPayments,
          amountHistory: amountHistory,
          startMonth: flat.createdAt.month,
          startYear: flat.createdAt.year,
        );
        final due = dues['totalDue'] as double;
        totalPending += due;
        if (due > 0) unpaidCount++;
      }

      // Initialize notifications listener done earlier in _loadData

      if (mounted) {
        setState(() {
          _totalFlats = flats.length;
          _totalPending = totalPending;
          _unpaidFlats = unpaidCount;
          _openComplaints = complaints
              .where((c) => c.status != 'resolved')
              .length;
          _isLoading = false;
        });
      }
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
        body: LoadingIndicator(message: 'Loading dashboard...'),
      );
    }

    final pages = [
      _buildDashboardPage(),
      FlatManagementScreen(societyId: _currentUser?.societyId ?? ''),
      PaymentManagementScreen(societyId: _currentUser?.societyId ?? ''),
      NoticeManagementScreen(
        societyId: _currentUser?.societyId ?? '',
        senderId: _currentUser?.id ?? '',
      ),
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
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_rounded),
              label: 'Flats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_rounded),
              label: 'Payments',
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
          // Drawer header
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
                    (_currentUser?.name ?? 'A').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentUser?.name ?? 'Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _society?.societyName ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Drawer items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.event_rounded, 'Events', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventManagementScreen(
                          societyId: _currentUser!.societyId,
                          senderId: _currentUser!.id),
                    ),
                  );
                }),
                _drawerItem(Icons.groups_rounded, 'Meetings', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeetingManagementScreen(
                          societyId: _currentUser!.societyId,
                          senderId: _currentUser!.id),
                    ),
                  );
                }),
                _drawerItem(
                    Icons.celebration_rounded, 'Party Approvals', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartyApprovalsScreen(
                          societyId: _currentUser!.societyId,
                          senderId: _currentUser!.id),
                    ),
                  );
                }),
                const Divider(),
                _drawerItem(Icons.settings_outlined, 'Maintenance Settings',
                    () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaintenanceSettingsScreen(
                          societyId: _currentUser!.societyId),
                    ),
                  ).then((_) => _loadData());
                }),
                _drawerItem(
                    Icons.report_rounded, 'Manage Complaints', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintManagementScreen(
                          societyId: _currentUser!.societyId),
                    ),
                  );
                }),
                _drawerItem(
                    Icons.info_outline_rounded, 'Society Details', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SocietyDetailsScreen(
                          societyId: _currentUser!.societyId),
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

  Widget _buildDashboardPage() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── App Bar Row ─────────────────────
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
                            color: AppTheme.contrastSecondary(context),
                          ),
                        ),
                        Text(
                          _currentUser?.name ?? 'Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.contrastText(context),
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

              // Society badge
              if (_society != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: AppTheme.glassDecoration(context).copyWith(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    child: Text(
                      '🏢 ${_society!.societyName}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // ─── Dashboard Cards Grid ────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
                children: [
                  PremiumCard(
                    title: 'Total Flats',
                    value: '$_totalFlats',
                    icon: Icons.apartment_rounded,
                    gradient: AppTheme.primaryGradient,
                  ),
                  PremiumCard(
                    title: 'Pending',
                    value: '₹${_totalPending.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: AppTheme.dangerGradient,
                  ),
                  PremiumCard(
                    title: 'Unpaid Flats',
                    value: '$_unpaidFlats',
                    icon: Icons.warning_amber_rounded,
                    gradient: AppTheme.amberGradient,
                  ),
                  PremiumCard(
                    title: 'Complaints',
                    value: '$_openComplaints',
                    icon: Icons.report_problem_rounded,
                    gradient: AppTheme.accentGradient,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ─── Quick Actions ───────────────────
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.contrastText(context),
                ),
              ),
              const SizedBox(height: 14),

              _quickActionTile(
                icon: Icons.event_rounded,
                title: 'Events',
                subtitle: 'Create & manage events',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventManagementScreen(
                        societyId: _currentUser!.societyId,
                        senderId: _currentUser!.id),
                  ),
                ),
              ),
              _quickActionTile(
                icon: Icons.groups_rounded,
                title: 'Meetings',
                subtitle: 'Schedule society meetings',
                color: const Color(0xFF7E57C2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeetingManagementScreen(
                        societyId: _currentUser!.societyId,
                        senderId: _currentUser!.id),
                  ),
                ),
              ),
              _quickActionTile(
                icon: Icons.celebration_rounded,
                title: 'Party Approvals',
                subtitle: 'Approve/reject party requests',
                color: AppTheme.warningColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PartyApprovalsScreen(
                        societyId: _currentUser!.societyId,
                        senderId: _currentUser!.id),
                  ),
                ),
              ),
              _quickActionTile(
                icon: Icons.settings_outlined,
                title: 'Maintenance Settings',
                subtitle: 'Set monthly maintenance amount',
                color: AppTheme.paidColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaintenanceSettingsScreen(
                        societyId: _currentUser!.societyId),
                  ),
                ).then((_) => _loadData()),
              ),
            ],
          ),
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

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.darkCardDecoration(context),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.contrastText(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.contrastSecondary(context),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }
}
