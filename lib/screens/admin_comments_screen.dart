import 'package:flutter/material.dart';
import '../services/feed_admin_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';

class AdminCommentsScreen extends StatefulWidget {
  const AdminCommentsScreen({super.key});

  @override
  State<AdminCommentsScreen> createState() => _AdminCommentsScreenState();
}

class _AdminCommentsScreenState extends State<AdminCommentsScreen> {
  final _service = FeedAdminService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text('Comments Moderation'),
      ),
      body: Column(
        children: [
          // ═══ SEARCH BAR ═══
          Container(
            padding: EdgeInsets.all(width * 0.03),
            color: AppColors.primary.withOpacity(0.05),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search comments...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: context.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ═══ LIST ═══
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getRecentComments(limit: 100),
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

                var comments = snapshot.data ?? [];

                // Filter kwa search
                if (_searchQuery.isNotEmpty) {
                  comments = comments.where((c) {
                    final text = (c['text'] ?? '').toString().toLowerCase();
                    final userName = (c['userName'] ?? '').toString().toLowerCase();
                    return text.contains(_searchQuery) ||
                        userName.contains(_searchQuery);
                  }).toList();
                }

                if (comments.isEmpty) {
                  return _buildEmptyState(width, _searchQuery.isNotEmpty);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.03),
                  itemCount: comments.length,
                  itemBuilder: (context, i) =>
                      _buildCommentCard(comments[i], width),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, double width) {
    final postId = comment['postId'] ?? '';
    final commentId = comment['commentId'] ?? '';
    final userName = comment['userName'] ?? 'User';
    final text = comment['text'] ?? '';
    final userAvatar = comment['userAvatar'] ?? '';
    final isHidden = comment['isHidden'] ?? false;
    final likesCount = comment['likesCount'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isHidden
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
          // ═══ User row ═══
          Row(
            children: [
              CircleAvatar(
                radius: width * 0.045,
                backgroundColor: AppColors.accentGold,
                backgroundImage: userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar.isEmpty
                    ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )
                    : null,
              ),
              SizedBox(width: width * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.036,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Post: ${postId.length > 12 ? '${postId.substring(0, 12)}...' : postId}',
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: context.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status chip
              if (isHidden)
                _chip('HIDDEN', Colors.red, width),
            ],
          ),
          SizedBox(height: width * 0.025),

          // ═══ Comment text ═══
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: Text(
              text.isNotEmpty ? text : '[No text]',
              style: TextStyle(
                fontSize: width * 0.034,
                color: context.textPrimary,
                height: 1.4,
                fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          // ═══ Stats ═══
          SizedBox(height: width * 0.02),
          Row(
            children: [
              Icon(Icons.favorite,
                  color: Colors.redAccent, size: width * 0.035),
              SizedBox(width: width * 0.008),
              Text('$likesCount',
                  style: TextStyle(fontSize: width * 0.03)),

              const Spacer(),

              // Reason (kama hidden)
              if (isHidden && (comment['hiddenReason'] ?? '').isNotEmpty)
                Text(
                  'Reason: ${comment['hiddenReason']}',
                  style: TextStyle(
                    fontSize: width * 0.026,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),

          // ═══ Actions ═══
          SizedBox(height: width * 0.025),
          const Divider(height: 1),
          SizedBox(height: width * 0.015),
          Row(
            children: [
              // View post
              Expanded(
                child: _actionBtn(
                  icon: Icons.visibility,
                  label: 'View Post',
                  color: AppColors.primary,
                  width: width,
                  onTap: () => _showPostInfo(postId, width),
                ),
              ),
              // Hide / Unhide
              Expanded(
                child: isHidden
                    ? _actionBtn(
                  icon: Icons.visibility,
                  label: 'Unhide',
                  color: Colors.green,
                  width: width,
                  onTap: () => _unhide(postId, commentId),
                )
                    : _actionBtn(
                  icon: Icons.visibility_off,
                  label: 'Hide',
                  color: Colors.orange,
                  width: width,
                  onTap: () => _hide(postId, commentId),
                ),
              ),
              // Delete
              Expanded(
                child: _actionBtn(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Colors.red,
                  width: width,
                  onTap: () => _delete(postId, commentId),
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
          Icon(icon, color: color, size: width * 0.045),
          SizedBox(height: width * 0.008),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: width * 0.024,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, bool searching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searching ? Icons.search_off : Icons.chat_bubble_outline,
            size: width * 0.15,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            searching ? 'No results found' : 'No comments yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ═══ ACTIONS ═══

  Future<void> _hide(String postId, String commentId) async {
    final reason = await _askReason('Hide comment', 'Why are you hiding this?');
    if (reason == null) return;
    final ok = await _service.hideComment(postId, commentId, reason);
    if (mounted) _snack(ok ? '✅ Comment hidden' : '❌ Failed');
  }

  Future<void> _unhide(String postId, String commentId) async {
    final ok = await _service.unhideComment(postId, commentId);
    if (mounted) _snack(ok ? '✅ Comment unhidden' : '❌ Failed');
  }

  Future<void> _delete(String postId, String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text(
            'This will permanently delete the comment. Cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _service.deleteComment(postId, commentId);
    if (mounted) _snack(ok ? '✅ Comment deleted' : '❌ Failed');
  }

  void _showPostInfo(String postId, double width) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Post ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              postId,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Copy this ID na utumie kufungua post kwenye Feed Moderation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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

  Future<String?> _askReason(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
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
}