import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/feed_admin_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _service = FeedAdminService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterReason = 'all';

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
        title: const Text('Reports Queue'),
      ),
      body: Column(
        children: [
          // ═══ SEARCH ═══
          Container(
            padding: EdgeInsets.all(width * 0.03),
            color: AppColors.primary.withOpacity(0.05),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(
                      () => _searchQuery = q.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search by reason, post ID...',
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

          // ═══ FILTER CHIPS ═══
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.03, vertical: width * 0.02),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', '🔔 All', width),
                  SizedBox(width: width * 0.02),
                  _filterChip('spam', '🚫 Spam', width),
                  SizedBox(width: width * 0.02),
                  _filterChip('inappropriate', '⚠️ Inappropriate', width),
                  SizedBox(width: width * 0.02),
                  _filterChip('harassment', '😡 Harassment', width),
                  SizedBox(width: width * 0.02),
                  _filterChip('false', '❌ False info', width),
                ],
              ),
            ),
          ),

          // ═══ LIST ═══
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getAllReports(limit: 200),
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

                var reports = snapshot.data ?? [];

                // Filter kwa search
                if (_searchQuery.isNotEmpty) {
                  reports = reports.where((r) {
                    final reason =
                    (r['reason'] ?? '').toString().toLowerCase();
                    final postId =
                    (r['postId'] ?? '').toString().toLowerCase();
                    final userId =
                    (r['reportedBy'] ?? '').toString().toLowerCase();
                    return reason.contains(_searchQuery) ||
                        postId.contains(_searchQuery) ||
                        userId.contains(_searchQuery);
                  }).toList();
                }

                // Filter kwa reason
                if (_filterReason != 'all') {
                  reports = reports.where((r) {
                    final reason =
                    (r['reason'] ?? '').toString().toLowerCase();
                    return reason.contains(_filterReason);
                  }).toList();
                }

                if (reports.isEmpty) {
                  return _buildEmptyState(width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.03),
                  itemCount: reports.length,
                  itemBuilder: (context, i) =>
                      _buildReportCard(reports[i], width, i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, double width) {
    final active = _filterReason == value;
    return GestureDetector(
      onTap: () => setState(() => _filterReason = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.035,
          vertical: width * 0.02,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.028,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
      Map<String, dynamic> report, double width, int index) {
    final reportId = report['id'] ?? '';
    final postId = report['postId'] ?? '';
    final reportedBy = report['reportedBy'] ?? '';
    final reason = report['reason'] ?? 'No reason';
    final createdAt = (report['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
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
          // ═══ Header row ═══
          Row(
            children: [
              // Report icon
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag,
                  color: Colors.orange,
                  size: width * 0.05,
                ),
              ),
              SizedBox(width: width * 0.03),

              // Report info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report #${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.036,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      _timeAgo(createdAt),
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Reason badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.025,
                  vertical: width * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reason.toUpperCase(),
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: width * 0.024,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.025),

          // ═══ Report details ═══
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  'Reason',
                  reason,
                  Icons.info_outline,
                  Colors.orange,
                  width,
                ),
                SizedBox(height: width * 0.02),
                _infoRow(
                  'Post ID',
                  postId.length > 20
                      ? '${postId.substring(0, 20)}...'
                      : postId,
                  Icons.article_outlined,
                  Colors.blue,
                  width,
                ),
                SizedBox(height: width * 0.02),
                _infoRow(
                  'Reported by',
                  reportedBy.length > 20
                      ? '${reportedBy.substring(0, 20)}...'
                      : reportedBy,
                  Icons.person_outline,
                  Colors.purple,
                  width,
                ),
              ],
            ),
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
              // Clear report
              Expanded(
                child: _actionBtn(
                  icon: Icons.check_circle_outline,
                  label: 'Clear',
                  color: Colors.green,
                  width: width,
                  onTap: () => _clearReport(reportId, postId),
                ),
              ),
              // Delete post
              Expanded(
                child: _actionBtn(
                  icon: Icons.delete_outline,
                  label: 'Delete Post',
                  color: Colors.red,
                  width: width,
                  onTap: () => _deletePost(postId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value,
      IconData icon,
      Color color,
      double width,
      ) {
    return Row(
      children: [
        Icon(icon, size: width * 0.035, color: color),
        SizedBox(width: width * 0.02),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: width * 0.03,
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: width * 0.03,
              color: context.textPrimary,
              fontFamily: label == 'Post ID' || label == 'Reported by'
                  ? 'monospace'
                  : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  Widget _buildEmptyState(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.08),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: width * 0.15,
              color: Colors.green,
            ),
          ),
          SizedBox(height: width * 0.05),
          Text(
            'No reports! 🎉',
            style: TextStyle(
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: width * 0.02),
          Text(
            'Feed is clean and safe',
            style: TextStyle(
              fontSize: width * 0.032,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══ ACTIONS ═══

  Future<void> _clearReport(String reportId, String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear this report?'),
        content: const Text(
            'This will remove the report and reset reportsCount for this post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Delete report
      await FirebaseFirestore.instance
          .collection('feed_reports')
          .doc(reportId)
          .delete();

      // Decrement post's reportsCount
      await FirebaseFirestore.instance
          .collection('feed_posts')
          .doc(postId)
          .update({
        'reportsCount': FieldValue.increment(-1),
      });

      if (mounted) _snack('✅ Report cleared');
    } catch (e) {
      if (mounted) _snack('❌ Failed: $e');
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
            'This will permanently delete the post and all its data. Cannot be undone.'),
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

    final ok = await _service.deletePost(postId);
    if (mounted) _snack(ok ? '✅ Post deleted' : '❌ Failed');
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

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Just now';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}