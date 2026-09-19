import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../widgets/review_analytics_widget.dart';
import '../widgets/review_card_widget.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _service = ReviewService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterRating = 'all';
  String _filterType = 'all';
  bool _showFeaturedOnly = false;
  bool _showWithPhotosOnly = false;
  bool _showUnrepliedOnly = false;

  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _service.getGlobalStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReviewModel> _filter(List<ReviewModel> all) {
    return all.where((r) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          r.userName.toLowerCase().contains(search) ||
          r.itemName.toLowerCase().contains(search) ||
          r.comment.toLowerCase().contains(search);

      final matchRating = _filterRating == 'all' ||
          r.rating.round().toString() == _filterRating;

      final matchType = _filterType == 'all' || r.itemType == _filterType;
      final matchFeatured = !_showFeaturedOnly || r.featured;
      final matchPhotos = !_showWithPhotosOnly || r.photos.isNotEmpty;
      final matchUnreplied = !_showUnrepliedOnly || r.adminReply.isEmpty;

      return matchSearch &&
          matchRating &&
          matchType &&
          matchFeatured &&
          matchPhotos &&
          matchUnreplied;
    }).toList();
  }

  Future<void> _replyToReview(ReviewModel review) async {
    final controller = TextEditingController(text: review.adminReply);

    final reply = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.reply, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(context.tr('reply_to_review')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.pageBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: context.tr('write_reply'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(context.tr('send_reply'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reply != null && reply.isNotEmpty) {
      await _service.replyToReview(review.id, reply);
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reply sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_review')),
        content: Text(
            'Delete ${review.userName}\'s review of ${review.itemName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteReview(review.id);
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Review deleted'),
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
        title: Text('⭐ ${context.tr('reviews_mgmt')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // STATS
                _buildStats(width, height),

                // SEARCH
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.01),
                  color: AppColors.primary,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr('search_reviews'),
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: height * 0.015),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // QUICK CHIPS
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.008),
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _quickChip(
                          '⭐ ${context.tr('featured')}',
                          _showFeaturedOnly,
                          () => setState(
                              () => _showFeaturedOnly = !_showFeaturedOnly),
                        ),
                        _quickChip(
                          '📸 ${context.tr('with_photos')}',
                          _showWithPhotosOnly,
                          () => setState(() =>
                              _showWithPhotosOnly = !_showWithPhotosOnly),
                        ),
                        _quickChip(
                          '💬 ${context.tr('unreplied')}',
                          _showUnrepliedOnly,
                          () => setState(
                              () => _showUnrepliedOnly = !_showUnrepliedOnly),
                        ),
                      ],
                    ),
                  ),
                ),

                // ANALYTICS
                if (_stats.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(width * 0.04),
                    color: context.pageBg,
                    child: ReviewAnalyticsWidget(stats: _stats),
                  ),

                // RATING FILTER
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.008),
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['all', '5', '4', '3', '2', '1'].map((r) {
                        final isSelected = _filterRating == r;
                        return GestureDetector(
                          onTap: () => setState(() => _filterRating = r),
                          child: Container(
                            margin: EdgeInsets.only(right: width * 0.02),
                            padding: EdgeInsets.symmetric(
                                horizontal: width * 0.035,
                                vertical: height * 0.006),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentGold
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              r == 'all' ? context.tr('all_ratings') : '$r ⭐',
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.024,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LIST
          StreamBuilder<List<ReviewModel>>(
            stream: _service.getAllReviews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()));
              }

              final reviews = _filter(snapshot.data ?? []);

              if (reviews.isEmpty) {
                return SliverFillRemaining(
                    child: _buildEmptyState(width, height));
              }

              return SliverPadding(
                padding: EdgeInsets.all(width * 0.04),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ReviewCard(
                      review: reviews[i],
                      onTap: () => _replyToReview(reviews[i]),
                      onReply: () => _replyToReview(reviews[i]),
                      onFeature: () async {
                        await _service.toggleFeatured(
                            reviews[i].id, !reviews[i].featured);
                        _loadStats();
                      },
                      onDelete: () => _deleteReview(reviews[i]),
                    ),
                    childCount: reviews.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      color: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              // Average
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(width * 0.035),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        (_stats['average'] ?? 0.0).toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StarRating(
                        rating: (_stats['average'] ?? 0.0).toDouble(),
                        size: 16,
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        '${_stats['total'] ?? 0} ${context.tr('reviews')}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.028,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: width * 0.02),
              // Quick stats
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _smallStat(
                            '✅', '${_stats['verified'] ?? 0}', context.tr('verified')),
                        _smallStat(
                            '📸', '${_stats['withPhotos'] ?? 0}', context.tr('photos')),
                      ],
                    ),
                    SizedBox(height: height * 0.01),
                    Row(
                      children: [
                        _smallStat(
                            '💬', '${_stats['replied'] ?? 0}', context.tr('replied')),
                        _smallStat(
                            '⭐', '${_stats['featured'] ?? 0}', context.tr('featured')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStat(String icon, String value, String label) {
    final width = MediaQuery.of(context).size.width;
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.02, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: context.cardBg.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: width * 0.04)),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.04,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.022,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, bool active, VoidCallback onTap) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentGold
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.026,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review,
                size: width * 0.2, color: context.textSecondary.withOpacity(0.3)),
            SizedBox(height: height * 0.02),
            Text(
              context.tr('no_reviews_found'),
              style: TextStyle(
                fontSize: width * 0.05,
                color: context.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}