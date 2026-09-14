import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../utils/colors.dart';
import 'admin_login_screen.dart';
import 'destinations_list_screen.dart';
import 'hotels_list_screen.dart';
import 'tours_list_screen.dart';
import 'bookings_list_screen.dart';
import 'users_list_screen.dart';
import 'deals_list_screen.dart';
import 'activities_list_screen.dart';
import 'admin_profile_screen.dart';
import '../widgets/analytics_widgets.dart';
import 'global_search_screen.dart';
import 'export_reports_screen.dart';


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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                _buildSectionTitle('📊 Overview', width),
                SizedBox(height: height * 0.015),
                _buildStatsGrid(width, height),
                SizedBox(height: height * 0.025),

                // ===== BOOKINGS STATUS =====
                _buildSectionTitle('📅 Bookings Status', width),
                SizedBox(height: height * 0.015),
                _buildBookingStatus(width, height),
                SizedBox(height: height * 0.025),

                // ===== QUICK ACTIONS =====
                _buildSectionTitle('🚀 Quick Actions', width),
                SizedBox(height: height * 0.015),
                _buildQuickActions(width, height),
                SizedBox(height: height * 0.025),

                // ===== MANAGEMENT =====
                _buildSectionTitle('📋 Management', width),
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
                // ===== RECENT BOOKINGS =====
                _buildSectionTitle('🔔 Recent Bookings', width),
                SizedBox(height: height * 0.015),
                _buildRecentBookings(width, height),
                SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );


  }

  Widget _buildBookingsChart(double width, double height) {
    return Container(
      height: height * 0.28,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: Icon(Icons.trending_up,
                    color: AppColors.accentGold, size: width * 0.05),
              ),
              SizedBox(width: width * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last 7 Days',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                          color: Colors.grey.shade800)),
                  Text('Bookings trend',
                      style: TextStyle(
                          fontSize: width * 0.028,
                          color: Colors.grey.shade500)),
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
    return Container(
      height: height * 0.3,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: Icon(Icons.attach_money,
                    color: AppColors.primary, size: width * 0.05),
              ),
              SizedBox(width: width * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Revenue',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                          color: Colors.grey.shade800)),
                  Text('Last 6 months',
                      style: TextStyle(
                          fontSize: width * 0.028,
                          color: Colors.grey.shade500)),
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
        color: Colors.white,
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
                  'Welcome back,',
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
                      Icon(Icons.logout, color: Colors.white, size: width * 0.03),
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
    );  }

  // ===== SECTION TITLE =====


  Widget _buildSectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
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
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: Colors.grey.shade600,
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
      {'icon': '📍', 'label': 'Destination', 'screen': 'destinations'},
      {'icon': '🏨', 'label': 'Hotel', 'screen': 'hotels'},
      {'icon': '🦁', 'label': 'Tour', 'screen': 'tours'},
      {'icon': '🎁', 'label': 'Deal', 'screen': 'deals'},
    ];
    return SizedBox(
      height: height * 0.12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () => _handleQuickAction(action['screen']!),
            child: Container(
              width: width * 0.25,
              margin: EdgeInsets.only(right: width * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(action['icon']!, style: TextStyle(fontSize: width * 0.08)),
                  SizedBox(height: height * 0.005),
                  Text(
                    '+ ${action['label']}',
                    style: TextStyle(
                      fontSize: width * 0.028,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add new $screen - Coming soon!')),
    );
  }

  // ===== MANAGEMENT LIST =====
  Widget _buildManagementList(double width, double height) {
    final items = [
      {'icon': '📍', 'label': 'Destinations', 'color': const Color(0xFF4facfe), 'count': _stats['destinations'] ?? 0},
      {'icon': '🏨', 'label': 'Hotels & Lodges', 'color': const Color(0xFF43e97b), 'count': _stats['hotels'] ?? 0},
      {'icon': '🦁', 'label': 'Tours & Safaris', 'color': const Color(0xFFfa709a), 'count': _stats['tours'] ?? 0},
      {'icon': '🎯', 'label': 'Activities', 'color': const Color(0xFFff9a9e), 'count': _stats['activities'] ?? 0},
      {'icon': '🎁', 'label': 'Deals', 'color': const Color(0xFFf093fb), 'count': _stats['deals'] ?? 0},
      {'icon': '📅', 'label': 'Bookings', 'color': const Color(0xFF667eea), 'count': _stats['bookings'] ?? 0},
      {'icon': '👥', 'label': 'Users', 'color': const Color(0xFF38f9d7), 'count': _stats['users'] ?? 0},
    ];

    return Column(
      children: items.map((item) {
        return GestureDetector(
          onTap: () => _handleManagementTap(item['label'] as String),
          child: Container(
            margin: EdgeInsets.only(bottom: height * 0.01),
            padding: EdgeInsets.all(width * 0.035),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  child: Text(item['icon'] as String, style: TextStyle(fontSize: width * 0.05)),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
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
        screen = const UsersListScreen();
        break;
    }
    if (screen != null) _navigateTo(screen);
  }

  // ===== RECENT BOOKINGS =====
  Widget _buildRecentBookings(double width, double height) {
    if (_recentBookings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: width * 0.15, color: Colors.grey.shade300),
              SizedBox(height: height * 0.01),
              Text(
                'No bookings yet',
                style: TextStyle(color: Colors.grey.shade500),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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