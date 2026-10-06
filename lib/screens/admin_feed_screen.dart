import 'package:flutter/material.dart';
import '../models/feed_post_model.dart';
import '../services/feed_admin_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import 'package:video_player/video_player.dart';

class AdminFeedScreen extends StatefulWidget {
  const AdminFeedScreen({super.key});

  @override
  State<AdminFeedScreen> createState() => _AdminFeedScreenState();
}

class _AdminFeedScreenState extends State<AdminFeedScreen>
    with SingleTickerProviderStateMixin {
  final FeedAdminService _service = FeedAdminService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);  // ⭐ 3 → 4
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('TURIVA Feed — Moderation'),
        actions: [
          // ⭐ Analytics button
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Feed Analytics',
            onPressed: () => _showAnalytics(context, width),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,  // ⭐ Scrollable kwa tabs 4
          tabs: const [
            Tab(text: 'All Posts', icon: Icon(Icons.dynamic_feed, size: 18)),
            Tab(text: 'Reported', icon: Icon(Icons.flag, size: 18)),
            Tab(text: 'Hidden', icon: Icon(Icons.visibility_off, size: 18)),
            Tab(text: 'Top', icon: Icon(Icons.trending_up, size: 18)),  // ⭐ NEW
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(_service.getAllPosts(), width, 'All Posts'),
          _buildPostList(_service.getReportedPosts(), width, 'Reported'),
          _buildPostList(_service.getHiddenPosts(), width, 'Hidden'),
          _buildPostList(_service.getTopPosts(), width, 'Top Posts'),  // ⭐ NEW
        ],
      ),
    );
  }

  Widget _buildPostList(
      Stream<List<FeedPostModel>> stream,
      double width,
      String label,
      ) {
    return StreamBuilder<List<FeedPostModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}\n\n'
                    '💡 Kama ni "requires index" — bofya link kwenye console.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox,
                    size: width * 0.15, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No $label yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(width * 0.03),
          itemCount: posts.length,
          itemBuilder: (context, i) => _buildPostCard(posts[i], width, i),
        );
      },
    );
  }

  Widget _buildPostCard(FeedPostModel post, double width, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: post.isHidden
            ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── User + status row ───
          Row(
            children: [
              // ⭐ Rank badge kwa Top 3 (kama ni Top tab)
              if (_tabController.index == 3 && index < 3)
                Container(
                  margin: EdgeInsets.only(right: width * 0.02),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.02,
                    vertical: width * 0.008,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: index == 0
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                          : index == 1
                          ? [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]
                          : [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: width * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              CircleAvatar(
                radius: width * 0.05,
                backgroundColor: AppColors.accentGold,
                backgroundImage: post.userAvatar.isNotEmpty
                    ? NetworkImage(post.userAvatar)
                    : null,
                child: post.userAvatar.isEmpty
                    ? Text(
                  post.userName.isNotEmpty
                      ? post.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.038,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: TextStyle(
                        fontSize: width * 0.028,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status chips
              if (post.isHidden)
                _chip('HIDDEN', Colors.red, width)
              else if (post.reportsCount > 0)
                _chip('${post.reportsCount} REPORTS', Colors.orange, width),
            ],
          ),
          SizedBox(height: width * 0.03),

          // ─── Image ───
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image.network(
                    post.imageUrl,
                    width: double.infinity,
                    height: width * 0.5,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: width * 0.5,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                  // ⭐ Video badge
                  if (post.isVideo)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ─── Caption ───
          if (post.caption.isNotEmpty) ...[
            SizedBox(height: width * 0.025),
            Text(
              post.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: width * 0.033,
                color: context.textPrimary,
              ),
            ),
          ],

          // ─── Location ───
          if (post.location.isNotEmpty) ...[
            SizedBox(height: width * 0.015),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: width * 0.035, color: context.textSecondary),
                SizedBox(width: width * 0.01),
                Expanded(
                  child: Text(
                    post.location,
                    style: TextStyle(
                      fontSize: width * 0.03,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // ─── Stats ───
          SizedBox(height: width * 0.025),
          Row(
            children: [
              // Likes
              Icon(Icons.favorite, color: Colors.redAccent, size: width * 0.04),
              SizedBox(width: width * 0.01),
              Text('${post.likesCount}',
                  style: TextStyle(fontSize: width * 0.032)),

              SizedBox(width: width * 0.035),

              // Comments
              Icon(Icons.chat_bubble_outline,
                  color: Colors.grey, size: width * 0.04),
              SizedBox(width: width * 0.01),
              Text('${post.commentsCount}',
                  style: TextStyle(fontSize: width * 0.032)),

              SizedBox(width: width * 0.035),

              // ⭐ Views
              Icon(Icons.visibility,
                  color: Colors.blue, size: width * 0.04),
              SizedBox(width: width * 0.01),
              Text('${post.viewsCount}',
                  style: TextStyle(fontSize: width * 0.032)),

              SizedBox(width: width * 0.035),

              // ⭐ Shares
              Icon(Icons.share_outlined,
                  color: Colors.purple, size: width * 0.04),
              SizedBox(width: width * 0.01),
              Text('${post.sharesCount}',
                  style: TextStyle(fontSize: width * 0.032)),

              const Spacer(),

              // Media type badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.02,
                  vertical: width * 0.008,
                ),
                decoration: BoxDecoration(
                  color: (post.isVideo ? Colors.red : Colors.blue)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.isVideo ? Icons.videocam : Icons.image,
                      size: width * 0.03,
                      color: post.isVideo ? Colors.red : Colors.blue,
                    ),
                    SizedBox(width: width * 0.008),
                    Text(
                      post.isVideo ? 'VIDEO' : 'IMAGE',
                      style: TextStyle(
                        fontSize: width * 0.022,
                        fontWeight: FontWeight.bold,
                        color: post.isVideo ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ─── Hidden reason (kama ipo) ───
          if (post.hiddenReason.isNotEmpty) ...[
            SizedBox(height: width * 0.02),
            Container(
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.red, size: width * 0.035),
                  SizedBox(width: width * 0.015),
                  Expanded(
                    child: Text(
                      'Reason: ${post.hiddenReason}',
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── Actions ───
          SizedBox(height: width * 0.03),
          const Divider(height: 1),
          SizedBox(height: width * 0.02),
          Row(
            children: [
              // View
              Expanded(
                child: _actionBtn(
                  icon: Icons.visibility,
                  label: 'View',
                  color: AppColors.primary,
                  width: width,
                  onTap: () => _showPreview(post, width),
                ),
              ),
              // Hide / Unhide
              Expanded(
                child: post.isHidden
                    ? _actionBtn(
                  icon: Icons.visibility,
                  label: 'Unhide',
                  color: Colors.green,
                  width: width,
                  onTap: () => _unhide(post),
                )
                    : _actionBtn(
                  icon: Icons.visibility_off,
                  label: 'Hide',
                  color: Colors.orange,
                  width: width,
                  onTap: () => _hide(post),
                ),
              ),
              // Clear reports
              if (post.reportsCount > 0)
                Expanded(
                  child: _actionBtn(
                    icon: Icons.check_circle_outline,
                    label: 'Clear',
                    color: Colors.blue,
                    width: width,
                    onTap: () => _clearReports(post),
                  ),
                ),
              // Delete
              Expanded(
                child: _actionBtn(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Colors.red,
                  width: width,
                  onTap: () => _delete(post),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, double width) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.025, vertical: width * 0.01),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: width * 0.026,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: width * 0.05),
          SizedBox(height: width * 0.01),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: width * 0.026,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ Actions ═══

  void _showPreview(FeedPostModel post, double width) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (post.imageUrl.isNotEmpty)
                Image.network(
                  post.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (post.isVideo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIDEO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (post.caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        post.caption,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _previewStat('❤️ ${post.likesCount}', 'Likes'),
                        _previewStat('💬 ${post.commentsCount}', 'Comments'),
                        _previewStat('👁️ ${post.viewsCount}', 'Views'),
                        _previewStat('📤 ${post.sharesCount}', 'Shares'),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',
                    style: TextStyle(color: AppColors.accentGold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  // ⭐ Analytics dialog
  void _showAnalytics(BuildContext context, double width) async {
    final stats = await _service.getFeedStats();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('Feed Analytics'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _analyticsRow('📸 Total Posts', '${stats['total'] ?? 0}'),
              _analyticsRow('👁️ Total Views', '${stats['totalViews'] ?? 0}'),
              _analyticsRow('❤️ Total Likes', '${stats['totalLikes'] ?? 0}'),
              _analyticsRow(
                  '💬 Total Comments', '${stats['totalComments'] ?? 0}'),
              _analyticsRow(
                  '📤 Total Shares', '${stats['totalShares'] ?? 0}'),
              const Divider(),
              _analyticsRow('🎥 Videos', '${stats['videos'] ?? 0}'),
              _analyticsRow('📷 Images', '${stats['images'] ?? 0}'),
              const Divider(),
              _analyticsRow('🚫 Hidden', '${stats['hidden'] ?? 0}'),
              _analyticsRow('⚠️ Reported', '${stats['reported'] ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _analyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _hide(FeedPostModel post) async {
    final reason = await _askReason('Hide post', 'Why are you hiding this?');
    if (reason == null) return;
    final ok = await _service.hidePost(post.id, reason);
    if (mounted) _snack(ok ? '✅ Post hidden' : '❌ Failed');
  }

  Future<void> _unhide(FeedPostModel post) async {
    final ok = await _service.unhidePost(post.id);
    if (mounted) _snack(ok ? '✅ Post unhidden' : '❌ Failed');
  }

  Future<void> _clearReports(FeedPostModel post) async {
    final ok = await _service.clearReports(post.id);
    if (mounted) _snack(ok ? '✅ Reports cleared' : '❌ Failed');
  }

  Future<void> _delete(FeedPostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
            'This will permanently delete the post. Cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _service.deletePost(post.id);
    if (mounted) _snack(ok ? '✅ Post deleted' : '❌ Failed');
  }

  Future<String?> _askReason(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(context, t);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}