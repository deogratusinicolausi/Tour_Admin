import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post_model.dart';
import '../services/feed_admin_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';

class AdminFeedAnalyticsScreen extends StatefulWidget {
  const AdminFeedAnalyticsScreen({super.key});

  @override
  State<AdminFeedAnalyticsScreen> createState() =>
      _AdminFeedAnalyticsScreenState();
}

class _AdminFeedAnalyticsScreenState extends State<AdminFeedAnalyticsScreen> {
  final _service = FeedAdminService();
  Map<String, int> _stats = {};
  List<FeedPostModel> _topPosts = [];
  List<Map<String, dynamic>> _topUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _service.getFeedStats();
      final topPosts = await _getTopPosts();
      final topUsers = await _getTopUsers();

      if (mounted) {
        setState(() {
          _stats = stats;
          _topPosts = topPosts;
          _topUsers = topUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 loadData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<FeedPostModel>> _getTopPosts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('feed_posts')
          .where('isHidden', isEqualTo: false)
          .limit(100)
          .get();

      final posts = snap.docs
          .map((d) => FeedPostModel.fromMap(d.data(), d.id))
          .toList();

      posts.sort((a, b) => b.likesCount.compareTo(a.likesCount));
      return posts.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getTopUsers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('feed_posts')
          .limit(500)
          .get();

      final userStats = <String, Map<String, dynamic>>{};

      for (var doc in snap.docs) {
        final data = doc.data();
        final userId = data['userId'] ?? '';
        final userName = data['userName'] ?? 'Unknown';
        final userAvatar = data['userAvatar'] ?? '';

        if (userId.isEmpty) continue;

        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'userId': userId,
            'userName': userName,
            'userAvatar': userAvatar,
            'posts': 0,
            'likes': 0,
            'views': 0,
          };
        }

        userStats[userId]!['posts'] =
            (userStats[userId]!['posts'] as int) + 1;
        userStats[userId]!['likes'] =
            (userStats[userId]!['likes'] as int) +
                ((data['likesCount'] ?? 0) as int);
        userStats[userId]!['views'] =
            (userStats[userId]!['views'] as int) +
                ((data['viewsCount'] ?? 0) as int);
      }

      final users = userStats.values.toList();
      users.sort((a, b) =>
          (b['posts'] as int).compareTo(a['posts'] as int));

      return users.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Feed Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ OVERVIEW ═══
              _sectionTitle('📊 Overview', width),
              SizedBox(height: width * 0.03),
              _buildOverviewGrid(width),
              SizedBox(height: width * 0.05),

              // ═══ MEDIA BREAKDOWN ═══
              _sectionTitle('🎥 Media Breakdown', width),
              SizedBox(height: width * 0.03),
              _buildMediaBreakdown(width),
              SizedBox(height: width * 0.05),

              // ═══ ENGAGEMENT ═══
              _sectionTitle('💫 Engagement Rate', width),
              SizedBox(height: width * 0.03),
              _buildEngagementCard(width),
              SizedBox(height: width * 0.05),

              // ═══ MODERATION ═══
              _sectionTitle('🛡️ Moderation Status', width),
              SizedBox(height: width * 0.03),
              _buildModerationGrid(width),
              SizedBox(height: width * 0.05),

              // ═══ TOP POSTS ═══
              _sectionTitle('🔥 Top 5 Posts', width),
              SizedBox(height: width * 0.03),
              _buildTopPosts(width),
              SizedBox(height: width * 0.05),

              // ═══ TOP USERS ═══
              _sectionTitle('👥 Top 5 Creators', width),
              SizedBox(height: width * 0.03),
              _buildTopUsers(width),
              SizedBox(height: width * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  // ═══ OVERVIEW GRID ═══
  Widget _buildOverviewGrid(double width) {
    final items = [
      {
        'icon': '📸',
        'label': 'Posts',
        'value': _stats['total'] ?? 0,
        'color': const Color(0xFF667eea),
      },
      {
        'icon': '👁️',
        'label': 'Views',
        'value': _stats['totalViews'] ?? 0,
        'color': const Color(0xFF4facfe),
      },
      {
        'icon': '❤️',
        'label': 'Likes',
        'value': _stats['totalLikes'] ?? 0,
        'color': const Color(0xFFfa709a),
      },
      {
        'icon': '💬',
        'label': 'Comments',
        'value': _stats['totalComments'] ?? 0,
        'color': const Color(0xFF43e97b),
      },
      {
        'icon': '📤',
        'label': 'Shares',
        'value': _stats['totalShares'] ?? 0,
        'color': const Color(0xFFff9a9e),
      },
      {
        'icon': '💾',
        'label': 'Saves',
        'value': _stats['totalSaves'] ?? 0,
        'color': const Color(0xFFf093fb),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: width * 0.025,
        mainAxisSpacing: width * 0.025,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final color = item['color'] as Color;
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
              Text(item['icon'] as String,
                  style: TextStyle(fontSize: width * 0.07)),
              SizedBox(height: width * 0.01),
              Text(
                _formatNumber(item['value'] as int),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item['label'] as String,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: width * 0.026,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══ MEDIA BREAKDOWN ═══
  Widget _buildMediaBreakdown(double width) {
    final videos = _stats['videos'] ?? 0;
    final images = _stats['images'] ?? 0;
    final total = videos + images;
    final videoPercent = total > 0 ? (videos / total * 100) : 0.0;
    final imagePercent = total > 0 ? (images / total * 100) : 0.0;

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _mediaStat(
                  '🎥',
                  'Videos',
                  videos,
                  videoPercent,
                  Colors.red,
                  width,
                ),
              ),
              Container(
                width: 1,
                height: width * 0.15,
                color: Colors.grey.withOpacity(0.2),
              ),
              Expanded(
                child: _mediaStat(
                  '📷',
                  'Images',
                  images,
                  imagePercent,
                  Colors.blue,
                  width,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.04),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: videos > 0 ? videos : 1,
                  child: Container(
                    height: width * 0.03,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  flex: images > 0 ? images : 1,
                  child: Container(
                    height: width * 0.03,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaStat(
      String icon,
      String label,
      int value,
      double percent,
      Color color,
      double width,
      ) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: width * 0.08)),
        SizedBox(height: width * 0.02),
        Text(
          _formatNumber(value),
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
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: width * 0.028,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══ ENGAGEMENT ═══
  Widget _buildEngagementCard(double width) {
    final total = _stats['total'] ?? 0;
    final likes = _stats['totalLikes'] ?? 0;
    final comments = _stats['totalComments'] ?? 0;
    final views = _stats['totalViews'] ?? 0;
    final shares = _stats['totalShares'] ?? 0;

    final avgLikes = total > 0 ? likes / total : 0;
    final avgComments = total > 0 ? comments / total : 0;
    final avgViews = total > 0 ? views / total : 0;
    final avgShares = total > 0 ? shares / total : 0;

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _engagementRow('❤️', 'Avg Likes/Post',
              avgLikes.toStringAsFixed(1), Colors.red, width),
          const Divider(height: 20),
          _engagementRow('💬', 'Avg Comments/Post',
              avgComments.toStringAsFixed(1), Colors.green, width),
          const Divider(height: 20),
          _engagementRow('👁️', 'Avg Views/Post',
              avgViews.toStringAsFixed(1), Colors.blue, width),
          const Divider(height: 20),
          _engagementRow('📤', 'Avg Shares/Post',
              avgShares.toStringAsFixed(1), Colors.purple, width),
        ],
      ),
    );
  }

  Widget _engagementRow(
      String emoji,
      String label,
      String value,
      Color color,
      double width,
      ) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: width * 0.06)),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: width * 0.034,
              color: context.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══ MODERATION ═══
  Widget _buildModerationGrid(double width) {
    final hidden = _stats['hidden'] ?? 0;
    final reported = _stats['reported'] ?? 0;
    final total = _stats['total'] ?? 0;
    final clean = total - hidden;
    final cleanPercent = total > 0 ? (clean / total * 100) : 100.0;

    return Row(
      children: [
        Expanded(
          child: _moderationCard(
            '🚫',
            'Hidden',
            hidden,
            Colors.red,
            width,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _moderationCard(
            '🚩',
            'Reported',
            reported,
            Colors.orange,
            width,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: _moderationCard(
            '✅',
            'Clean',
            '${cleanPercent.toStringAsFixed(0)}%',
            Colors.green,
            width,
          ),
        ),
      ],
    );
  }

  Widget _moderationCard(
      String emoji,
      String label,
      dynamic value,
      Color color,
      double width,
      ) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: width * 0.06)),
          SizedBox(height: width * 0.015),
          Text(
            value is int ? _formatNumber(value) : value.toString(),
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: width * 0.028,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ TOP POSTS ═══
  Widget _buildTopPosts(double width) {
    if (_topPosts.isEmpty) {
      return _emptyCard('No posts yet', width);
    }

    return Column(
      children: List.generate(_topPosts.length, (i) {
        final post = _topPosts[i];
        return Container(
          margin: EdgeInsets.only(bottom: width * 0.02),
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: width * 0.08,
                height: width * 0.08,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: i == 0
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                        : i == 1
                        ? [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]
                        : i == 2
                        ? [const Color(0xFFCD7F32), const Color(0xFF8B4513)]
                        : [
                      AppColors.primary.withOpacity(0.7),
                      AppColors.primary
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#${i + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.03,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),

              // Thumbnail
              if (post.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl,
                    width: width * 0.13,
                    height: width * 0.13,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: width * 0.13,
                      height: width * 0.13,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image),
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
                      post.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.034,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (post.caption.isNotEmpty)
                      Text(
                        post.caption,
                        style: TextStyle(
                          fontSize: width * 0.028,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite,
                          color: Colors.redAccent, size: width * 0.035),
                      SizedBox(width: width * 0.008),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.visibility,
                          color: Colors.blue, size: width * 0.032),
                      SizedBox(width: width * 0.008),
                      Text(
                        '${post.viewsCount}',
                        style: TextStyle(fontSize: width * 0.028),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  // ═══ TOP USERS ═══
  Widget _buildTopUsers(double width) {
    if (_topUsers.isEmpty) {
      return _emptyCard('No users yet', width);
    }

    return Column(
      children: List.generate(_topUsers.length, (i) {
        final user = _topUsers[i];
        return Container(
          margin: EdgeInsets.only(bottom: width * 0.02),
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: width * 0.08,
                height: width * 0.08,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: i == 0
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                        : i == 1
                        ? [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]
                        : i == 2
                        ? [const Color(0xFFCD7F32), const Color(0xFF8B4513)]
                        : [AppColors.primary, AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#${i + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.03,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),

              // Avatar
              CircleAvatar(
                radius: width * 0.055,
                backgroundColor: AppColors.accentGold,
                backgroundImage: (user['userAvatar'] ?? '').isNotEmpty
                    ? NetworkImage(user['userAvatar'])
                    : null,
                child: (user['userAvatar'] ?? '').isEmpty
                    ? Text(
                  (user['userName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              SizedBox(width: width * 0.03),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['userName'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.034,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${user['posts']} posts • ${user['likes']} likes',
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptyCard(String msg, double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.08),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          msg,
          style: TextStyle(color: context.textSecondary),
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}