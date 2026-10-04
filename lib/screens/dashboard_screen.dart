import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../utils/colors.dart';
import 'admin_login_screen.dart';
import 'destinations_list_screen.dart';
import 'hotels_list_screen.dart';
import 'tours_list_screen.dart';
import 'bookings_list_screen.dart';
import 'deals_list_screen.dart';
import 'activities_list_screen.dart';
import 'admin_profile_screen.dart';
import '../widgets/analytics_widgets.dart';
import 'global_search_screen.dart';
import 'export_reports_screen.dart';
import 'beaches_list_screen.dart';
import 'mountains_list_screen.dart';
import 'culture_list_screen.dart';
import 'food_list_screen.dart';
import 'admin_chats_list_screen.dart';
import '../services/chat_service.dart';
import 'admin_notifications_screen.dart';
import '../services/admin_notification_service.dart';
import 'admin_reviews_screen.dart';
import 'admin_users_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_cancellations_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import '../services/turiva_chat_service.dart';
import 'wishlist_insights_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _bookingsLast7Days = [];
  List<Map<String, dynamic>> _revenueByMonth = [];
  Map<String, int> _itemTypeDistribution = {};

  Map<String, int> _stats = {};
  int _pendingBookings = 0;
  int _confirmedBookings = 0;
  List<Map<String, dynamic>> _recentBookings = [];

  // ⭐ Real counts for cards
  int _paymentsCount = 0;
  int _couponsCount = 0;
  int _cancellationsCount = 0;
  int _wishlistInsightsCount = 0;
  bool _isLoading = true;
  String _userName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadData();
    // ⭐️ Listen for new chat messages
    ChatService().listenForNewMessages();
    TurivaChatService().listenForNewMessages();  // ⭐ ONGEZA
    // ⭐️ Listen for new notifications
    AdminNotificationService().listenForNewNotifications();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    // Safe wrapper — never throws
    Future<T> safe<T>(Future<T> future, T fallback) async {
      try {
        return await future;
      } catch (e) {
        debugPrint('🔥 Query failed: $e');
        return fallback;
      }
    }

    final results = await Future.wait([
      safe(_dashboardService.getAllStats(), <String, int>{}),
      safe(_dashboardService.getPendingBookings(), 0),
      safe(_dashboardService.getConfirmedBookings(), 0),
      safe(_dashboardService.getRecentBookings(), <Map<String, dynamic>>[]),
      safe(_dashboardService.getBookingsLast7Days(), <Map<String, dynamic>>[]),
      safe(_dashboardService.getRevenueByMonth(), <Map<String, dynamic>>[]),
      safe(_dashboardService.getItemTypeDistribution(), <String, int>{}),
    ]);

    final stats = results[0] as Map<String, int>;
    final pending = results[1] as int;
    final confirmed = results[2] as int;
    final recent = (results[3] as List).cast<Map<String, dynamic>>();
    final bookingsData = (results[4] as List).cast<Map<String, dynamic>>();
    final revenueData = (results[5] as List).cast<Map<String, dynamic>>();
    final itemTypes = results[6] as Map<String, int>;

    final user = _auth.getCurrentUser();
    String name = 'Admin';
    if (user != null) {
      name = user.displayName ?? user.email?.split('@')[0] ?? 'Admin';
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _pendingBookings = pending;
        _confirmedBookings = confirmed;
        _recentBookings = recent;
        _bookingsLast7Days = bookingsData;
        _revenueByMonth = revenueData;
        _itemTypeDistribution = itemTypes;
        _userName = name;
        _isLoading = false;
      });
      _loadCardCounts(); // still loads the extra card counts
    }
  }

  // ⭐ Load counts for the extra cards
  Future<void> _loadCardCounts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Payments — count all docs
      final paymentsSnap = await firestore.collection('payments').get();

      // Coupons — all active
      final couponsSnap = await firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();

      // Cancellations — bookings with status cancelled
      final cancellationsSnap = await firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: 'cancelled')
          .get();

      // Wishlist insights — count wishlist items
      final wishlistsSnap = await firestore.collection('wishlists').get();

      if (mounted) {
        setState(() {
          _paymentsCount = paymentsSnap.docs.length;
          _couponsCount = couponsSnap.docs.length;
          _cancellationsCount = cancellationsSnap.docs.length;
          _wishlistInsightsCount = wishlistsSnap.docs.length;
        });
      }
    } catch (e) {
      debugPrint('🔥 loadCardCounts: $e');
    }
  }

  void _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // ⭐️ Theme listener
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.pageBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== ERROR BANNER =====
                      if (_stats.isEmpty && !_isLoading)
                        Container(
                          margin: EdgeInsets.only(bottom: height * 0.02),
                          padding: EdgeInsets.all(width * 0.03),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: Colors.red),
                              SizedBox(width: width * 0.02),
                              const Expanded(
                                child: Text(
                                  'Some data failed to load. Pull down to retry.',
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // ===== HEADER =====
                      _buildHeader(width, height),
                      SizedBox(height: height * 0.025),

                      // ===== STATS GRID =====
                      _buildSectionTitle('📊 ${context.tr('overview')}', width),
                      SizedBox(height: height * 0.015),
                      _buildStatsGrid(width, height),
                      SizedBox(height: height * 0.025),

                      // ===== BOOKINGS STATUS =====
                      _buildSectionTitle('📅 Bookings Status', width),
                      SizedBox(height: height * 0.015),
                      _buildBookingStatus(width, height),
                      SizedBox(height: height * 0.025),

                      // ===== QUICK ACTIONS =====
                      _buildSectionTitle('🚀 ${context.tr('quick_actions')}', width),
                      SizedBox(height: height * 0.015),
                      _buildQuickActions(width, height),
                      SizedBox(height: height * 0.025),

                      // ===== MANAGEMENT =====
                      _buildSectionTitle('📋 ${context.tr('management')}', width),
                      SizedBox(height: height * 0.015),
                      _buildManagementList(width, height),
                      SizedBox(height: height * 0.025),
                      // ===== ANALYTICS =====
                      _buildSectionTitle('📈 Analytics', width),
                      SizedBox(height: height * 0.015),

                      _buildBookingsChart(width, height),
                      SizedBox(height: height * 0.025),

                      _buildSectionTitle('💰 Revenue (Last 6 Months)', width),
                      SizedBox(height: height * 0.015),
                      _buildRevenueChart(width, height),
                      SizedBox(height: height * 0.025),

                      _buildSectionTitle('🎯 Booking Types', width),
                      SizedBox(height: height * 0.015),
                      _buildItemTypeChart(width, height),
                      SizedBox(height: height * 0.025),

                      // ===== RECENT BOOKINGS =====
                      _buildSectionTitle('🔔 Recent Bookings', width),
                      SizedBox(height: height * 0.015),
                      _buildRecentBookings(width, height),
                      SizedBox(height: height * 0.02),

                      // ===== GESTURE CONTROL BUTTON =====
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/gesture-control'),
                          icon: const Icon(Icons.pan_tool_alt),
                          label: const Text('Gesture Control (Beta)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBookingsChart(double width, double height) {
    final isDark = context.isDark;
    return Container(
      height: height * 0.28,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.accentGold,
                  size: width * 0.05,
                ),
              ),
              SizedBox(width: width * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.038,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Bookings trend',
                    style: TextStyle(
                      fontSize: width * 0.028,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          Expanded(child: BookingsLineChart(data: _bookingsLast7Days)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(double width, double height) {
    final isDark = context.isDark;
    return Container(
      height: height * 0.3,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: AppColors.primary,
                  size: width * 0.05,
                ),
              ),
              SizedBox(width: width * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Revenue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.038,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Last 6 months',
                    style: TextStyle(
                      fontSize: width * 0.028,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          Expanded(child: RevenueBarChart(data: _revenueByMonth)),
        ],
      ),
    );
  }

  Widget _buildItemTypeChart(double width, double height) {
    return Container(
      height: height * 0.25,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ItemTypePieChart(data: _itemTypeDistribution),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== ROW 1: AVATAR + WELCOME + NOTIFICATIONS =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminProfileScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                child: Container(
                  padding: EdgeInsets.all(width * 0.025),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: width * 0.08,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),

              // Welcome text — full width, no wrapping
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${context.tr('welcome_back')},',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: width * 0.032,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.003),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$_userName',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.052,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        Text(
                          '👋',
                          style: TextStyle(fontSize: width * 0.045),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notification icons row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bell
                  StreamBuilder<int>(
                    stream: AdminNotificationService().getUnreadCount(),
                    builder: (context, snapshot) {
                      final unread = snapshot.data ?? 0;
                      return _headerIconBtn(
                        icon: Icons.notifications_outlined,
                        badge: unread,
                        width: width,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminNotificationsScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                      );
                    },
                  ),
                  SizedBox(width: width * 0.01),
                  // Chat
                  StreamBuilder<int>(
                    stream: ChatService().getTotalUnread(),
                    builder: (context, snapshot) {
                      final unread = snapshot.data ?? 0;
                      return _headerIconBtn(
                        icon: Icons.chat_bubble_outline,
                        badge: unread,
                        width: width,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminChatsListScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                      );
                    },
                  ),
                  SizedBox(width: width * 0.01),
                  // Turiva Chat
                  StreamBuilder<int>(
                    stream: TurivaChatService().getTotalUnreadByAdmin(),
                    builder: (context, snapshot) {
                      final unread = snapshot.data ?? 0;
                      return _headerIconBtn(
                        icon: Icons.forum_outlined,
                        badge: unread,
                        width: width,
                        onTap: () {},
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: height * 0.02),

          // ===== ROW 2: SUPER ADMIN + REFRESH + LOGOUT =====
          Row(
            children: [
              // SUPER ADMIN badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                  vertical: height * 0.006,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt,
                      color: AppColors.accentGold,
                      size: width * 0.035,
                    ),
                    SizedBox(width: width * 0.01),
                    Text(
                      'SUPER ADMIN',
                      style: TextStyle(
                        color: AppColors.accentGold,
                        fontSize: width * 0.028,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Refresh button
              GestureDetector(
                onTap: () {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔄 Refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(width * 0.025),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: width * 0.045,
                  ),
                ),
              ),

              SizedBox(width: width * 0.02),

              // Logout button
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: width * 0.035,
                      ),
                      SizedBox(width: width * 0.012),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER — Notification icon button with badge
  // ============================================================
  Widget _headerIconBtn({
    required IconData icon,
    required int badge,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.022),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: width * 0.048,
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== SECTION TITLE =====

  Widget _buildSectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  // ===== STATS GRID =====
  Widget _buildStatsGrid(double width, double height) {
    final stats = [
      {
        'icon': '👥',
        'label': context.tr('users'),
        'value': _stats['users'] ?? 0,
        'color': const Color(0xFF667eea),
      },
      {
        'icon': '📅',
        'label': context.tr('bookings'),
        'value': _stats['bookings'] ?? 0,
        'color': const Color(0xFFf093fb),
      },
      {
        'icon': '📍',
        'label': context.tr('destinations'),
        'value': _stats['destinations'] ?? 0,
        'color': const Color(0xFF4facfe),
      },
      {
        'icon': '🏨',
        'label': context.tr('hotels'),
        'value': _stats['hotels'] ?? 0,
        'color': const Color(0xFF43e97b),
      },
      {
        'icon': '🦁',
        'label': context.tr('tours'),
        'value': _stats['tours'] ?? 0,
        'color': const Color(0xFFfa709a),
      },
      {
        'icon': '🎁',
        'label': context.tr('deals'),
        'value': _stats['deals'] ?? 0,
        'color': const Color(0xFFff9a9e),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: width * 0.02,
        mainAxisSpacing: width * 0.02,
        childAspectRatio: 0.85,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final color = stat['color'] as Color;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['icon'] as String,
                style: TextStyle(fontSize: width * 0.07),
              ),
              SizedBox(height: height * 0.005),
              Text(
                (stat['value'] as int).toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat['label'] as String,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: width * 0.025,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== BOOKING STATUS =====
  Widget _buildBookingStatus(double width, double height) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            icon: '⏳',
            label: context.tr('pending'),
            value: _pendingBookings,
            color: Colors.orange,
            width: width,
            height: height,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _buildStatusCard(
            icon: '✅',
            label: context.tr('confirmed'),
            value: _confirmedBookings,
            color: Colors.green,
            width: width,
            height: height,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String icon,
    required String label,
    required int value,
    required Color color,
    required double width,
    required double height,
  }) {
    final isDark = context.isDark;
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: TextStyle(fontSize: width * 0.06)),
          ),
          SizedBox(width: width * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: width * 0.06,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: width * 0.03,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== QUICK ACTIONS =====
  Widget _buildQuickActions(double width, double height) {
    final actions = [
      {'icon': '🔍', 'label': 'Search', 'screen': 'search'},
      {'icon': '📤', 'label': 'Reports', 'screen': 'reports'},
      {'icon': '💰', 'label': 'Payments', 'screen': 'payments'},
      {'icon': '📊', 'label': 'Analytics', 'screen': 'analytics'},
      {'icon': '⭐', 'label': 'Reviews', 'screen': 'reviews'},
      {'icon': '❤️', 'label': 'Wishlist', 'screen': 'wishlist'},
      {'icon': '📍', 'label': 'Destination', 'screen': 'destinations'},
      {'icon': '🏨', 'label': 'Hotel', 'screen': 'hotels'},
      {'icon': '🦁', 'label': 'Tour', 'screen': 'tours'},
      {'icon': '🎁', 'label': 'Deal', 'screen': 'deals'},
    ];

    // Responsive card width
    double cardWidth;

    if (width < 360) {
      // Small phones
      cardWidth = 105;
    } else if (width < 600) {
      // Normal phones
      cardWidth = 120;
    } else if (width < 900) {
      // Large phones / small tablets
      cardWidth = 135;
    } else {
      // iPad / large tablets
      cardWidth = 150;
    }

    // Responsive widget height
    final double quickActionHeight = width < 600 ? 105 : 120;

    return SizedBox(
      height: quickActionHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: cardWidth,
              child: GestureDetector(
                onTap: () => _handleQuickAction(action['screen']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action['icon']!,
                        style: TextStyle(
                          fontSize: width < 600 ? 30 : 34,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Flexible(
                        child: Text(
                          '+ ${action['label']}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width < 600 ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleQuickAction(String screen) {
    if (screen == 'search') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
      );
      return;
    }
    if (screen == 'reports') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExportReportsScreen()),
      );
      return;
    }
    if (screen == 'payments') {
      // ⭐ ONGEZA
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()),
      );
      return;
    }
    if (screen == 'analytics') {
      // ⭐ ONGEZA
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
      );
      return;
    }
    if (screen == 'reviews') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminReviewsScreen()),
      );
      return;
    }
    if (screen == 'wishlist') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WishlistInsightsScreen()),
      );
      return;
    }
    if (screen == 'destinations') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DestinationsListScreen()),
      );
      return;
    }
    if (screen == 'hotels') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HotelsListScreen()),
      );
      return;
    }
    if (screen == 'tours') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ToursListScreen()),
      );
      return;
    }
    if (screen == 'deals') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DealsListScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Add new $screen - Coming soon!')));
  }

  // ===== MANAGEMENT LIST =====
  Widget _buildManagementList(double width, double height) {
    final items = [
      {
        'type': 'destinations',
        'icon': '📍',
        'label': context.tr('destinations'),
        'color': const Color(0xFF4facfe),
        'count': _stats['destinations'] ?? 0,
      },
      {
        'type': 'hotels',
        'icon': '🏨',
        'label': context.tr('hotels'),
        'color': const Color(0xFF43e97b),
        'count': _stats['hotels'] ?? 0,
      },
      {
        'type': 'tours',
        'icon': '🦁',
        'label': context.tr('tours'),
        'color': const Color(0xFFfa709a),
        'count': _stats['tours'] ?? 0,
      },
      {
        'type': 'beaches',
        'icon': '🏖️',
        'label': context.tr('beaches'),
        'color': const Color(0xFF00bcd4),
        'count': _stats['beaches'] ?? 0,
      },
      {
        'type': 'mountains',
        'icon': '🏔️',
        'label': context.tr('mountains'),
        'color': const Color(0xFF795548),
        'count': _stats['mountains'] ?? 0,
      },
      {
        'type': 'culture',
        'icon': '🎭',
        'label': context.tr('culture'),
        'color': const Color(0xFF9c27b0),
        'count': _stats['culture'] ?? 0,
      },
      {
        'type': 'food',
        'icon': '🍛',
        'label': context.tr('food'),
        'color': const Color(0xFFff5722),
        'count': _stats['food'] ?? 0,
      },
      {
        'type': 'activities',
        'icon': '🎯',
        'label': context.tr('activities'),
        'color': const Color(0xFFff9a9e),
        'count': _stats['activities'] ?? 0,
      },
      {
        'type': 'deals',
        'icon': '🎁',
        'label': context.tr('deals'),
        'color': const Color(0xFFf093fb),
        'count': _stats['deals'] ?? 0,
      },
      {
        'type': 'reviews',
        'icon': '⭐',
        'label': context.tr('reviews'),
        'color': Colors.amber,
        'count': _stats['reviews'] ?? 0
      }, // ⭐ ONGEZA
      {
        'type': 'live_chats',
        'icon': '💬',
        'label': context.tr('live_chats'),
        'color': Colors.purple,
        'count': 0
      },
      {
        'type': 'bookings',
        'icon': '📅',
        'label': context.tr('bookings'),
        'color': const Color(0xFF667eea),
        'count': _stats['bookings'] ?? 0,
      },
      {
        'type': 'users',
        'icon': '👥',
        'label': context.tr('users'),
        'color': const Color(0xFF38f9d7),
        'count': _stats['users'] ?? 0,
      },
      {'type': 'payments', 'icon': '💰', 'label': context.tr('payments'), 'color': Colors.green, 'count': _paymentsCount},
      {'type': 'analytics', 'icon': '📊', 'label': context.tr('analytics'), 'color': Colors.indigo, 'count': _stats['bookings'] ?? 0},
      {'type': 'coupons', 'icon': '🎁', 'label': context.tr('coupons'), 'color': Colors.pink, 'count': _couponsCount},
      {'type': 'cancellations', 'icon': '❌', 'label': context.tr('cancellations'), 'color': Colors.red, 'count': _cancellationsCount},
      {
        'type': 'wishlist_insights',
        'icon': '❤️',
        'label': context.tr('wishlist_insights'),
        'color': const Color(0xFFfa709a),
        'count': _wishlistInsightsCount,
      },
    ];

    final isDark = context.isDark;
    return Column(
      children: items.map((item) {
        return GestureDetector(
          onTap: () => _handleManagementTap(item['type'] as String),
          child: Container(
            margin: EdgeInsets.only(bottom: height * 0.01),
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(width * 0.025),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['icon'] as String,
                    style: TextStyle(fontSize: width * 0.05),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.025,
                    vertical: height * 0.004,
                  ),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (item['count'] as int).toString(),
                    style: TextStyle(
                      color: item['color'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.03,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.02),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.textMuted,
                  size: width * 0.035,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleManagementTap(String label) {
    Widget? screen;
    switch (label) {
      case 'destinations':
        screen = const DestinationsListScreen();
        break;
      case 'hotels':
        screen = const HotelsListScreen();
        break;
      case 'tours':
        screen = const ToursListScreen();
        break;
      case 'beaches':
        screen = const BeachesListScreen();
        break;
      case 'mountains':
        screen = const MountainsListScreen();
        break;
      case 'culture':
        screen = const CultureListScreen();
        break;
      case 'food':
        screen = const FoodListScreen();
        break;
      case 'activities':
        screen = const ActivitiesListScreen();
        break;
      case 'deals':
        screen = const DealsListScreen();
        break;
      case 'bookings':
        screen = const BookingsListScreen();
        break;
      case 'users':
        screen = const AdminUsersScreen();
        break;
      case 'chats':
        screen = const AdminChatsListScreen();
        break;
      case 'notifications':
        screen = const AdminNotificationsScreen();
        break;
      case 'reviews':
        screen = const AdminReviewsScreen();
        break;
      case 'payments':
        screen = const AdminPaymentsScreen();
        break;
      case 'analytics':
        screen = const AdminAnalyticsScreen();
        break;
      case 'coupons':
        screen = const AdminCouponsScreen();
        break;
      case 'cancellations':
        screen = const AdminCancellationsScreen();
        break;
      case 'wishlist_insights':
        screen = const WishlistInsightsScreen();
        break;
      // case 'Live Chats':
      //   screen = const AdminTurivaChatsScreen();
      //   break;
    }
    if (screen != null) _navigateTo(screen);
  }

  // ===== RECENT BOOKINGS =====
  Widget _buildRecentBookings(double width, double height) {
    final isDark = context.isDark;
    if (_recentBookings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(width * 0.05),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: width * 0.15,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: height * 0.01),
              Text(
                context.tr('no_bookings'),
                style: TextStyle(color: context.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentBookings.map((booking) {
        final status = booking['status'] as String;
        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'confirmed':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'cancelled':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.orange;
            statusIcon = Icons.access_time;
        }

        return Container(
          margin: EdgeInsets.only(bottom: height * 0.01),
          padding: EdgeInsets.all(width * 0.035),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: width * 0.05),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['itemName'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.035,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'by ${booking['userName'] ?? 'Guest'}',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: width * 0.028,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${booking['amount']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: width * 0.035,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
