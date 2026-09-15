import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model2.dart';
import '../services/user_service.dart';
import '../utils/colors.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final _service = UserService();
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookings = await _service.getUserBookings(widget.user.uid);
    final reviews = await _service.getUserReviews(widget.user.uid);
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotification() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final send = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📢 Send Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Send',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (send == true &&
        titleController.text.isNotEmpty &&
        bodyController.text.isNotEmpty) {
      await _service.sendNotification(
        uid: widget.user.uid,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final user = widget.user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverAppBar(
            expandedHeight: height * 0.3,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                const BoxDecoration(gradient: AppColors.mainGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,  // ⭐ ONGEZA HII
                  children: [
                    CircleAvatar(
                      radius: width * 0.11,
                      backgroundColor: Colors.white,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: width * 0.12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    SizedBox(height: height * 0.015),
                    Text(
                      user.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: width * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QUICK STATS
                  Row(
                    children: [
                      _quickStat('📅', '${user.totalBookings}', 'Bookings',
                          Colors.blue, width),
                      _quickStat(
                          '💰',
                          '\$${user.totalSpent.toStringAsFixed(0)}',
                          'Spent',
                          Colors.green,
                          width),
                      _quickStat('⭐', '${user.totalReviews}', 'Reviews',
                          AppColors.accentGold, width),
                    ],
                  ),
                  SizedBox(height: height * 0.025),

                  // ACCOUNT INFO
                  _sectionTitle('📋 Account Information', width),
                  SizedBox(height: height * 0.015),
                  Container(
                    padding: EdgeInsets.all(width * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoRow('🆔 User ID',
                            user.uid.substring(0, 12), width),
                        Divider(height: height * 0.02),
                        _infoRow('🎭 Role', user.role.toUpperCase(), width),
                        Divider(height: height * 0.02),
                        _infoRow('🔔 Status', user.status.toUpperCase(),
                            width),
                        if (user.phone.isNotEmpty) ...[
                          Divider(height: height * 0.02),
                          _infoRow('📱 Phone', user.phone, width),
                        ],
                        if (user.country.isNotEmpty) ...[
                          Divider(height: height * 0.02),
                          _infoRow('🌍 Country', user.country, width),
                        ],
                        Divider(height: height * 0.02),
                        _infoRow('🕐 Last Login', user.lastLoginAgo, width),
                        Divider(height: height * 0.02),
                        _infoRow('📅 Joined', user.timeAgo, width),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // ACTION BUTTONS
                  _sectionTitle('⚡ Actions', width),
                  SizedBox(height: height * 0.015),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon: Icons.email,
                          label: 'Email',
                          color: Colors.blue,
                          onTap: () async {
                            final uri = Uri.parse('mailto:${user.email}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      if (user.phone.isNotEmpty)
                        Expanded(
                          child: _actionButton(
                            icon: Icons.phone,
                            label: 'Call',
                            color: Colors.green,
                            onTap: () async {
                              final uri =
                              Uri.parse('tel:${user.phone}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            width: width,
                          ),
                        ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.notifications,
                          label: 'Notify',
                          color: Colors.orange,
                          onTap: _sendNotification,
                          width: width,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.025),

                  // RECENT BOOKINGS
                  if (_bookings.isNotEmpty) ...[
                    _sectionTitle(
                        '📅 Recent Bookings (${_bookings.length})', width),
                    SizedBox(height: height * 0.015),
                    ..._bookings.take(5).map((b) => _buildBookingCard(
                        b, width, height)),
                    SizedBox(height: height * 0.025),
                  ],

                  // RECENT REVIEWS
                  if (_reviews.isNotEmpty) ...[
                    _sectionTitle(
                        '⭐ Recent Reviews (${_reviews.length})', width),
                    SizedBox(height: height * 0.015),
                    ..._reviews.take(3).map((r) => _buildReviewCard(
                        r, width, height)),
                    SizedBox(height: height * 0.025),
                  ],

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _quickStat(String emoji, String value, String label, Color color,
      double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.all(width * 0.03),
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
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: width * 0.08)),
            SizedBox(height: width * 0.015),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.045,
                color: Colors.grey.shade900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: width * 0.026,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, double width) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: width * 0.032,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: width * 0.032,
            color: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: width * 0.04),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: width * 0.06),
            SizedBox(height: width * 0.01),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: width * 0.028,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      Map<String, dynamic> b, double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.01),
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (b['itemImage'] ?? '').toString().isNotEmpty
                ? Image.network(
              b['itemImage'],
              width: width * 0.12,
              height: width * 0.12,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: width * 0.12,
                height: width * 0.12,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 20),
              ),
            )
                : Container(
              width: width * 0.12,
              height: width * 0.12,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 20),
            ),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b['itemName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${b['currency'] ?? 'USD'} ${(b['amount'] ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: b['bookingStatus'] == 'confirmed'
                  ? Colors.green.withOpacity(0.15)
                  : b['bookingStatus'] == 'cancelled'
                  ? Colors.red.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (b['bookingStatus'] ?? '').toString().toUpperCase(),
              style: TextStyle(
                color: b['bookingStatus'] == 'confirmed'
                    ? Colors.green
                    : b['bookingStatus'] == 'cancelled'
                    ? Colors.red
                    : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      Map<String, dynamic> r, double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.01),
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < ((r['rating'] ?? 0) as num).floor()
                      ? Icons.star
                      : Icons.star_border,
                  color: AppColors.accentGold,
                  size: 14,
                );
              }),
              const Spacer(),
              Text(
                r['itemName'] ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            r['comment'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}