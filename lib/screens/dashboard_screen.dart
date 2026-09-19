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
import '../services/payment_service.dart';
import 'admin_reviews_screen.dart';
import '../services/review_service.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'admin_turiva_chats_screen.dart';
import '../services/turiva_chat_service.dart';

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
    setState(() => _isLoading = true);

    final stats = await _dashboardService.getAllStats();
    final pending = await _dashboardService.getPendingBookings();
    final confirmed = await _dashboardService.getConfirmedBookings();
    final recent = await _dashboardService.getRecentBookings();
    final bookingsData = await _dashboardService.getBookingsLast7Days();
    final revenueData = await _dashboardService.getRevenueByMonth();
    final itemTypes = await _dashboardService.getItemTypeDistribution();

    // Get user name
    final user = _auth.getCurrentUser();
    String name = 'Admin';
    if (user != null) {
      // Try to get from Firestore users collection
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
      padding: EdgeInsets.all(width * 0.05),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('welcome_back')},',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: width * 0.035,
                  ),
                ),
                SizedBox(height: height * 0.005),
                Text(
                  '$_userName 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: height * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⚡ SUPER ADMIN',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: width * 0.028,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<int>(
                stream: AdminNotificationService().getUnreadCount(),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminNotificationsScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              StreamBuilder<int>(
                stream: ChatService().getTotalUnread(),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminChatsListScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              StreamBuilder<int>(
                stream: TurivaChatService().getTotalUnreadByAdmin(),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.forum_outlined, color: Colors.white),
                        onPressed: (){},
                        // onPressed: () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (_) => const AdminTurivaChatsScreen(),
                        //     ),
                        //   ).then((_) => _loadData());
                        // },
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(width: width * 0.02),
          Column(
            children: [
              // ⭐ ADMIN PROFILE - CLICKABLE
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
                  padding: EdgeInsets.all(width * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: width * 0.1,
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: width * 0.03,
                      ),
                      SizedBox(width: width * 0.01),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.025,
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

  // ===== SECTION TITLE =====

  Widget _buildSectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: context.isDark ? Colors.white : Colors.grey.shade800,
      ),
    );
  }

  // ===== STATS GRID =====
  Widget _buildStatsGrid(double width, double height) {
    final stats = [
      {
        'icon': '👥',
        'label': 'Users',
        'value': _stats['users'] ?? 0,
        'color': const Color(0xFF667eea),
      },
      {
        'icon': '📅',
        'label': 'Bookings',
        'value': _stats['bookings'] ?? 0,
        'color': const Color(0xFFf093fb),
      },
      {
        'icon': '📍',
        'label': 'Destinations',
        'value': _stats['destinations'] ?? 0,
        'color': const Color(0xFF4facfe),
      },
      {
        'icon': '🏨',
        'label': 'Hotels',
        'value': _stats['hotels'] ?? 0,
        'color': const Color(0xFF43e97b),
      },
      {
        'icon': '🦁',
        'label': 'Tours',
        'value': _stats['tours'] ?? 0,
        'color': const Color(0xFFfa709a),
      },
      {
        'icon': '🎁',
        'label': 'Deals',
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
            label: 'Pending',
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
            label: 'Confirmed',
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
            color: Colors.black.withOpacity(0.05),
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
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                        color: Colors.black.withOpacity(0.05),
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
        'icon': '📍',
        'label': 'Destinations',
        'color': const Color(0xFF4facfe),
        'count': _stats['destinations'] ?? 0,
      },
      {
        'icon': '🏨',
        'label': 'Hotels & Lodges',
        'color': const Color(0xFF43e97b),
        'count': _stats['hotels'] ?? 0,
      },
      {
        'icon': '🦁',
        'label': 'Tours & Safaris',
        'color': const Color(0xFFfa709a),
        'count': _stats['tours'] ?? 0,
      },
      {
        'icon': '🏖️',
        'label': 'Beaches',
        'color': const Color(0xFF00bcd4),
        'count': _stats['beaches'] ?? 0,
      },
      {
        'icon': '🏔️',
        'label': 'Mountains',
        'color': const Color(0xFF795548),
        'count': _stats['mountains'] ?? 0,
      },
      {
        'icon': '🎭',
        'label': 'Culture',
        'color': const Color(0xFF9c27b0),
        'count': _stats['culture'] ?? 0,
      },
      {
        'icon': '🍛',
        'label': 'Food',
        'color': const Color(0xFFff5722),
        'count': _stats['food'] ?? 0,
      },
      {
        'icon': '🎯',
        'label': 'Activities',
        'color': const Color(0xFFff9a9e),
        'count': _stats['activities'] ?? 0,
      },
      {
        'icon': '🎁',
        'label': 'Deals',
        'color': const Color(0xFFf093fb),
        'count': _stats['deals'] ?? 0,
      },
      {'icon': '⭐', 'label': 'Reviews', 'color': Colors.amber, 'count': _stats['reviews'] ?? 0},    // ⭐ ONGEZA
      {'icon': '💬', 'label': 'Live Chats', 'color': Colors.purple, 'count': 0},
      {
        'icon': '📅',
        'label': 'Bookings',
        'color': const Color(0xFF667eea),
        'count': _stats['bookings'] ?? 0,
      },
      {
        'icon': '👥',
        'label': 'Users',
        'color': const Color(0xFF38f9d7),
        'count': _stats['users'] ?? 0,
      },
      {'icon': '💰', 'label': 'Payments', 'color': Colors.green, 'count': 0},
      {'icon': '📊', 'label': 'Analytics', 'color': Colors.indigo, 'count': 0},
      {'icon': '🎁', 'label': 'Coupons', 'color': Colors.pink, 'count': 0},
      {'icon': '❌', 'label': 'Cancellations', 'color': Colors.red, 'count': 0},
    ];

    final isDark = context.isDark;
    return Column(
      children: items.map((item) {
        return GestureDetector(
          onTap: () => _handleManagementTap(item['label'] as String),
          child: Container(
            margin: EdgeInsets.only(bottom: height * 0.01),
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                      color: isDark ? Colors.white : Colors.grey.shade800,
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
                  color: Colors.grey.shade400,
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
      case 'Destinations':
        screen = const DestinationsListScreen();
        break;
      case 'Hotels & Lodges':
        screen = const HotelsListScreen();
        break;
      case 'Tours & Safaris':
        screen = const ToursListScreen();
        break;
      case 'Beaches':
        screen = const BeachesListScreen();
        break;
      case 'Mountains':
        screen = const MountainsListScreen();
        break;
      case 'Culture':
        screen = const CultureListScreen();
        break;
      case 'Food':
        screen = const FoodListScreen();
        break;
      case 'Activities':
        screen = const ActivitiesListScreen();
        break;
      case 'Deals':
        screen = const DealsListScreen();
        break;
      case 'Bookings':
        screen = const BookingsListScreen();
        break;
      case 'Users':
        screen = const AdminUsersScreen();
        break;
      case 'Chats':
        screen = const AdminChatsListScreen();
        break;
      case 'Notifications':
        screen = const AdminNotificationsScreen();
        break;
      case 'Reviews':
        screen = const AdminReviewsScreen();
        break;
      case 'Payments':
        screen = const AdminPaymentsScreen();
        break;
      case 'Analytics':
        screen = const AdminAnalyticsScreen();
        break;
      case 'Coupons':
        screen = const AdminCouponsScreen();
        break;
      case 'Cancellations':
        screen = const AdminCancellationsScreen();
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
                'No bookings yet',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
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
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
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
                      ),
                    ),
                    Text(
                      'by ${booking['userName'] ?? 'Guest'}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
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
