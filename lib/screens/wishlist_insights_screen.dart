import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme_helper.dart';
import 'wishlist_item_users_screen.dart';
import '../services/wishlist_insights_service.dart';
import '../services/export_service.dart';
import '../utils/colors.dart';
import '../services/sound_service.dart';

class WishlistInsightsScreen extends StatefulWidget {
  const WishlistInsightsScreen({super.key});

  @override
  State<WishlistInsightsScreen> createState() => _WishlistInsightsScreenState();
}

class _WishlistInsightsScreenState extends State<WishlistInsightsScreen> {
  final _service = WishlistInsightsService();
  final _exportService = ExportService();

  // ===== STATE (live) =====
  int _liveUpdates = 0; // ⬅️ Counter ya updates (kwa animation)

  @override
  void initState() {
    super.initState();
    // ⭐ Anzisha sound listener (static method)
    SoundService.startWishlistListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleExport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 Inatengeneza CSV...'),
          backgroundColor: AppColors.accentGold,
          duration: Duration(seconds: 1),
        ),
      );

      await _exportService.exportWishlistToCsv();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CSV imetengenezwa!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: const Text('❤️ Wishlist Insights'),
        backgroundColor: context.isDark ? const Color(0xFF1A237E) : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _handleExport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            _buildHeader(width, height),
            SizedBox(height: height * 0.025),

            // ===== LIVE FEED =====
            _buildSectionTitle('⚡ Live Activity', width),
            SizedBox(height: height * 0.015),
            _buildLiveFeed(width, height),
            SizedBox(height: height * 0.025),

            // ===== STATS GRID (LIVE) =====
            _buildSectionTitle('📊 Overview', width),
            SizedBox(height: height * 0.015),
            StreamBuilder<Map<String, dynamic>>(
              stream: _service.streamTotalStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                      ),
                    ),
                  );
                }
                return _buildStatsGrid(width, height, snapshot.data!);
              },
            ),
            SizedBox(height: height * 0.025),

            // ===== CATEGORY BREAKDOWN (LIVE) =====
            StreamBuilder<Map<String, int>>(
              stream: _service.streamCategoryBreakdown(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? {};
                if (categories.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('🎨 Category Breakdown', width),
                    SizedBox(height: height * 0.015),
                    _buildCategoryPieChart(width, height, categories),
                    SizedBox(height: height * 0.015),
                    _buildCategoryBreakdown(width, height, categories),
                    SizedBox(height: height * 0.025),
                  ],
                );
              },
            ),

            // ===== POPULARITY LEADERBOARD (LIVE) =====
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.streamTopLikedItems(limit: 20),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('🏆 Top 20 Most Liked', width),
                    SizedBox(height: height * 0.015),
                    _buildLeaderboard(width, height, items),
                    SizedBox(height: height * 0.025),
                  ],
                );
              },
            ),

            // ===== TRENDING THIS WEEK (LIVE) =====
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.streamTrendingItems(limit: 10),
              builder: (context, snapshot) {
                final trending = snapshot.data ?? [];
                if (trending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('🔥 Trending This Week', width),
                    SizedBox(height: height * 0.015),
                    _buildTrendingList(width, height, trending),
                    SizedBox(height: height * 0.04),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== GLASS APP BAR =====
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  '❤️ Wishlist Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Export CSV',
                onPressed: _handleExport,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== HEADER =====
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
          Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '❤️',
              style: TextStyle(fontSize: width * 0.08),
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wishlist Analytics',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: width * 0.035,
                  ),
                ),
                SizedBox(height: height * 0.005),
                Text(
                  'User Preferences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: height * 0.008),
                // ===== LIVE INDICATOR (animated) =====
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 2)),
                  builder: (context, snapshot) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: height * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Blinking dot
                          AnimatedOpacity(
                            opacity: (snapshot.data as int?)?.isEven == true ? 1.0 : 0.3,
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: width * 0.015),
                          Text(
                            '⚡ LIVE',
                            style: TextStyle(
                              color: AppColors.accentGold,
                              fontSize: width * 0.025,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle(String title, double width) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * 0.045,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ===== STATS GRID =====
  Widget _buildStatsGrid(double width, double height, Map<String, dynamic> stats) {
    final cards = [
      {
        'icon': '❤️',
        'label': 'Total Likes',
        'value': '${stats['totalLikes'] ?? 0}',
        'color': const Color(0xFFfa709a),
      },
      {
        'icon': '👥',
        'label': 'Unique Users',
        'value': '${stats['uniqueUsers'] ?? 0}',
        'color': const Color(0xFF667eea),
      },
      {
        'icon': '📍',
        'label': 'Unique Items',
        'value': '${stats['uniqueItems'] ?? 0}',
        'color': const Color(0xFF4facfe),
      },
      {
        'icon': '📊',
        'label': 'Avg Likes/Item',
        'value': (stats['avgLikesPerItem'] ?? 0.0).toStringAsFixed(1),
        'color': const Color(0xFF43e97b),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: width * 0.03,
        mainAxisSpacing: width * 0.03,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final color = card['color'] as Color;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(width * 0.035),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card['icon'] as String,
                    style: TextStyle(fontSize: width * 0.06),
                  ),
                  Text(
                    card['label'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: width * 0.026,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                card['value'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.07,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== CATEGORY BREAKDOWN =====
  Widget _buildCategoryBreakdown(double width, double height, Map<String, int> categories) {
    final total = categories.values.fold<int>(0, (a, b) => a + b);

    // Sort by count desc
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: sorted.map((entry) {
          final type = entry.key;
          final count = entry.value;
          final percent = total > 0 ? (count / total) * 100 : 0.0;
          final icon = _service.getTypeIcon(type);

          return Padding(
            padding: EdgeInsets.symmetric(vertical: width * 0.02),
            child: Row(
              children: [
                // Icon + Name
                SizedBox(
                  width: width * 0.32,
                  child: Row(
                    children: [
                      Text(icon,
                          style: TextStyle(fontSize: width * 0.04)),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: width * 0.028,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 10,
                      color: Colors.grey.shade200,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (percent / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.mainGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: width * 0.03),

                // Count + Percentage
                SizedBox(
                  width: width * 0.18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: width * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: width * 0.024,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===== LEADERBOARD =====
  Widget _buildLeaderboard(double width, double height, List<Map<String, dynamic>> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final rank = i + 1;
        final likes = (item['likes'] as int?) ?? 0;
        final imageUrl = (item['itemImage'] ?? '').toString();
        final type = (item['itemType'] ?? '').toString();

        // Rank color
        Color rankColor;
        if (rank == 1) {
          rankColor = const Color(0xFFFFD700); // Gold
        } else if (rank == 2) {
          rankColor = const Color(0xFFC0C0C0); // Silver
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32); // Bronze
        } else {
          rankColor = Colors.grey.shade400;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WishlistItemUsersScreen(
                  itemId: (item['itemId'] ?? '').toString(),
                  itemName: (item['itemName'] ?? '').toString(),
                  itemType: (item['itemType'] ?? '').toString(),
                ),
              ),
            );
          },
          child: Container(
          margin: EdgeInsets.only(bottom: height * 0.01),
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: rank <= 3
                  ? rankColor.withOpacity(0.6)
                  : context.borderColor,
              width: rank <= 3 ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: width * 0.1,
                height: width * 0.1,
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: rankColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: width * 0.032,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: width * 0.13,
                  height: width * 0.13,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey),
                    ),
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['itemName'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.036,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.003),
                    Row(
                      children: [
                        Text(
                          _service.getTypeIcon(type),
                          style: TextStyle(fontSize: width * 0.028),
                        ),
                        SizedBox(width: width * 0.01),
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: width * 0.024,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Likes count
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                  vertical: height * 0.008,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFfa709a).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: const Color(0xFFfa709a),
                      size: width * 0.035,
                    ),
                    SizedBox(width: width * 0.01),
                    Text(
                      '$likes',
                      style: TextStyle(
                        color: const Color(0xFFfa709a),
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.032,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      }).toList(),
    );
  }

  // ===== TRENDING LIST =====
  Widget _buildTrendingList(double width, double height, List<Map<String, dynamic>> trending) {
    return SizedBox(
      height: height * 0.25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: trending.length,
        itemBuilder: (context, i) {
          final item = trending[i];
          final likes = (item['likes'] as int?) ?? 0;
          final imageUrl = (item['itemImage'] ?? '').toString();
          final type = (item['itemType'] ?? '').toString();

          return Container(
            width: width * 0.4,
            margin: EdgeInsets.only(right: width * 0.03),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentGold.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _trendingFallback(width),
                    )
                      : _trendingFallback(width),

                  // Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Rank badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentGold,
                            AppColors.accentGold.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${i + 1}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Likes
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.redAccent, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '$likes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item['itemName'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.032,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: height * 0.003),
                          Text(
                            '${_service.getTypeIcon(type)} ${type.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.022,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  // ===== WEEKLY TREND LINE CHART =====
  Widget _buildWeeklyTrendChart(double width, double height) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.streamWeeklyLikeTrend(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: height * 0.25,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: AppColors.accentGold,
            ),
          );
        }

        final trend = snapshot.data ?? [];
        if (trend.isEmpty) return const SizedBox.shrink();

        final maxLikes = trend
            .map((e) => (e['likes'] as int?) ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b);

        return Container(
          padding: EdgeInsets.all(width * 0.04),
          height: height * 0.25,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    maxLikes > 0 ? (maxLikes / 4).ceilToDouble() : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= trend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          trend[i]['day'].toString(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval:
                        maxLikes > 0 ? (maxLikes / 4).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (trend.length - 1).toDouble(),
              minY: 0,
              maxY: (maxLikes > 0 ? maxLikes + 1 : 5).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trend.length,
                    (i) => FlSpot(
                      i.toDouble(),
                      ((trend[i]['likes'] as int?) ?? 0).toDouble(),
                    ),
                  ),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentGold,
                      AppColors.accentGold.withOpacity(0.4),
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.accentGold,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGold.withOpacity(0.3),
                        AppColors.accentGold.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
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

  // ===== PIE CHART =====
  Widget _buildCategoryPieChart(
      double width, double height, Map<String, int> categories) {
    final total = categories.values.fold<int>(0, (a, b) => a + b);
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors for pie segments
    final colors = [
      const Color(0xFFfa709a), // pink
      const Color(0xFF667eea), // purple
      const Color(0xFF4facfe), // blue
      const Color(0xFF43e97b), // green
      const Color(0xFFff9a9e), // coral
      const Color(0xFFff9800), // orange
      const Color(0xFF9c27b0), // deep purple
      const Color(0xFF00bcd4), // cyan
      const Color(0xFF795548), // brown
      const Color(0xFFf093fb), // light pink
    ];

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: height * 0.25,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: width * 0.12,
                sections: sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final percent = total > 0 ? (item.value / total) * 100 : 0.0;

                  return PieChartSectionData(
                    value: item.value.toDouble(),
                    color: colors[i % colors.length],
                    title: '${percent.toStringAsFixed(0)}%',
                    radius: width * 0.1,
                    titleStyle: TextStyle(
                      fontSize: width * 0.026,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: height * 0.02),

          // Legend
          Wrap(
            spacing: width * 0.03,
            runSpacing: height * 0.01,
            alignment: WrapAlignment.center,
            children: sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final color = colors[i % colors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: width * 0.015),
                  Text(
                    '${_service.getTypeIcon(item.key)} ${item.key.toUpperCase()}',
                    style: TextStyle(
                      fontSize: width * 0.026,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== LIVE FEED =====
  Widget _buildLiveFeed(double width, double height) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.streamRecentLikes(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: height * 0.1,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: AppColors.accentGold,
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'No activity yet',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: width * 0.032,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final ts = item['createdAt'] as Timestamp?;
              final timeAgo = _timeAgo(ts);
              final icon = _service.getTypeIcon(
                  (item['itemType'] ?? '').toString());

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: width * 0.02,
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(width * 0.02),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? Colors.green.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '❤️',
                            style: TextStyle(
                              fontSize: width * 0.04,
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.03),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['itemName'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.032,
                                  color: context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: height * 0.003),
                              Row(
                                children: [
                                  Text(
                                    icon,
                                    style: TextStyle(
                                        fontSize: width * 0.024),
                                  ),
                                  SizedBox(width: width * 0.01),
                                  Text(
                                    (item['itemType'] ?? '').toString().toUpperCase(),
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: width * 0.024,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Time ago
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: i == 0
                                ? Colors.green
                                : context.textSecondary,
                            fontSize: width * 0.026,
                            fontWeight: i == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(
                      color: context.dividerColor,
                      height: 1,
                    ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ===== TIME AGO HELPER =====
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return 'N/A';

    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _trendingFallback(double width) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.local_fire_department,
          size: width * 0.1,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}