import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/wishlist_insights_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';

class WishlistItemUsersScreen extends StatefulWidget {
  final String itemId;
  final String itemName;
  final String itemType;

  const WishlistItemUsersScreen({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.itemType,
  });

  @override
  State<WishlistItemUsersScreen> createState() =>
      _WishlistItemUsersScreenState();
}

class _WishlistItemUsersScreenState extends State<WishlistItemUsersScreen> {
  final _service = WishlistInsightsService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _service.getUsersWhoLiked(widget.itemId);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return 'N/A';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('❤️ ${widget.itemName}'),
        backgroundColor: context.isDark ? const Color(0xFF1A237E) : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentGold,
        ),
      )
          : _users.isEmpty
          ? _buildEmptyState(width, height)
          : RefreshIndicator(
        color: AppColors.accentGold,
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: EdgeInsets.all(width * 0.04),
          itemCount: _users.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return _buildHeader(width, height);
            }
            return _buildUserCard(_users[i - 1], width, height);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _service.getTypeIcon(widget.itemType),
            style: TextStyle(fontSize: width * 0.1),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: height * 0.005),
                Text(
                  '${_users.length} users liked this',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
      Map<String, dynamic> user, double width, double height) {
    final name = (user['userName'] ?? 'Unknown').toString();
    final email = (user['userEmail'] ?? '').toString();
    final image = (user['userImage'] ?? '').toString();
    final likedAt = user['likedAt'] as Timestamp?;

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.012),
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
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: width * 0.06,
            backgroundColor: AppColors.primary.withOpacity(context.isDark ? 0.3 : 0.1),
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.045,
              ),
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
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.036,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  SizedBox(height: height * 0.003),
                  Text(
                    email,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: width * 0.028,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.favorite,
                color: Color(0xFFfa709a),
                size: 16,
              ),
              SizedBox(height: height * 0.005),
              Text(
                _timeAgo(likedAt),
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: width * 0.026,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: width * 0.15,
              color: context.textMuted,
            ),
            SizedBox(height: height * 0.02),
            Text(
              'No users yet',
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'No users have liked this item.',
              style: TextStyle(
                fontSize: width * 0.032,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}