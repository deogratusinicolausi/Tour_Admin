import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterStatus = 'all';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _service.getUserStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _changeRole(UserModel u) async {
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _buildRoleSheet(u),
    );
    if (role != null && role != u.role) {
      final ok = await _service.updateUserRole(u.uid, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ Role updated to $role' : '❌ Failed'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadStats();
      }
    }
  }

  Future<void> _toggleBan(UserModel u) async {
    final isBanned = u.status == 'banned';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isBanned ? 'Unban User?' : 'Ban User?'),
        content: Text(
          isBanned
              ? 'Restore access for ${u.name}?'
              : 'Block ${u.name} from using the app?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: isBanned ? Colors.green : Colors.red),
              child: Text(isBanned ? 'Unban' : 'Ban')),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _service.updateUserStatus(
          u.uid, isBanned ? 'active' : 'banned');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? (isBanned ? '✅ User unbanned' : '🚫 User banned')
                : '❌ Failed'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadStats();
      }
    }
  }

  Future<void> _viewDetails(UserModel u) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildDetailsSheet(u),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('👥 Users'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // STATS
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Row(
              children: [
                _statBadge('Total', _stats['total'] ?? 0, Colors.white, width),
                _statBadge('Customers', _stats['customers'] ?? 0, Colors.blue, width),
                _statBadge('Admins', _stats['admins'] ?? 0, AppColors.accentGold, width),
                _statBadge('Banned', _stats['banned'] ?? 0, Colors.red, width),
              ],
            ),
          ),

          // SEARCH + FILTER
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
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
                SizedBox(height: height * 0.015),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'customer',
                      'admin',
                      'superAdmin'
                    ].map((role) {
                      final isSelected = _filterRole == role;
                      return GestureDetector(
                        onTap: () => setState(() => _filterRole = role),
                        child: Container(
                          margin: EdgeInsets.only(right: width * 0.02),
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                              vertical: height * 0.008),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentGold
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color:
                              isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.028,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _service.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? [];
                final users = all.where((u) {
                  final matchSearch = _searchQuery.isEmpty ||
                      u.name.toLowerCase().contains(_searchQuery) ||
                      u.email.toLowerCase().contains(_searchQuery);
                  final matchRole =
                      _filterRole == 'all' || u.role == _filterRole;
                  return matchSearch && matchRole;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: width * 0.2, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          'No users found',
                          style: TextStyle(
                              fontSize: width * 0.05,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: users.length,
                  itemBuilder: (context, i) =>
                      _buildUserCard(users[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int value, Color color, double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(vertical: width * 0.025),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                  color: color,
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: width * 0.022),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel u, double width, double height) {
    Color roleColor;
    switch (u.role) {
      case 'superAdmin':
        roleColor = Colors.red;
        break;
      case 'admin':
        roleColor = AppColors.accentGold;
        break;
      default:
        roleColor = Colors.blue;
    }

    final isBanned = u.status == 'banned';

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
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
        border: isBanned
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: width * 0.07,
                  backgroundColor: AppColors.primary,
                  backgroundImage: u.photoUrl.isNotEmpty
                      ? NetworkImage(u.photoUrl)
                      : null,
                  child: u.photoUrl.isEmpty
                      ? Text(
                    u.name.isNotEmpty
                        ? u.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.06,
                        fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                SizedBox(width: width * 0.03),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              u.name,
                              style: TextStyle(
                                fontSize: width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBanned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BANNED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: height * 0.003),
                      Text(
                        u.email,
                        style: TextStyle(
                            fontSize: width * 0.028,
                            color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.005),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          u.role.toUpperCase(),
                          style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.015),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.visibility,
                    label: 'View',
                    color: AppColors.primary,
                    onTap: () => _viewDetails(u),
                    width: width,
                  ),
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.admin_panel_settings,
                    label: 'Role',
                    color: AppColors.accentGold,
                    onTap: () => _changeRole(u),
                    width: width,
                  ),
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: _actionBtn(
                    icon: isBanned ? Icons.lock_open : Icons.block,
                    label: isBanned ? 'Unban' : 'Ban',
                    color: isBanned ? Colors.green : Colors.red,
                    onTap: () => _toggleBan(u),
                    width: width,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: width * 0.025),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: width * 0.04),
            SizedBox(width: width * 0.01),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: width * 0.028,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSheet(UserModel u) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: width * 0.05),
          Text(
            'Change Role for ${u.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: width * 0.03),
          _roleTile(u, 'customer', '👤', 'Customer', 'Regular app user', Colors.blue, width),
          _roleTile(u, 'admin', '🛡️', 'Admin', 'Can manage content', AppColors.accentGold, width),
          _roleTile(u, 'superAdmin', '👑', 'Super Admin', 'Full access', Colors.red, width),
          SizedBox(height: width * 0.03),
        ],
      ),
    );
  }

  Widget _roleTile(UserModel u, String role, String emoji, String title,
      String desc, Color color, double width) {
    final isCurrent = u.role == role;
    return GestureDetector(
      onTap: () => Navigator.pop(context, role),
      child: Container(
        margin: EdgeInsets.only(bottom: width * 0.02),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: isCurrent ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? color : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: width * 0.07)),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSheet(UserModel u) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: height * 0.015),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary, size: 28),
                    SizedBox(width: width * 0.03),
                    const Text('User Profile',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: width * 0.15,
                          backgroundColor: AppColors.primary,
                          backgroundImage: u.photoUrl.isNotEmpty
                              ? NetworkImage(u.photoUrl)
                              : null,
                          child: u.photoUrl.isEmpty
                              ? Text(
                            u.name.isNotEmpty
                                ? u.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.12,
                                fontWeight: FontWeight.bold),
                          )
                              : null,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      Center(
                        child: Text(u.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: height * 0.005),
                      Center(
                        child: Text(u.email,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                      ),
                      SizedBox(height: height * 0.03),
                      _detailRow('User ID', u.uid.substring(0, 12), width),
                      _detailRow('Role', u.role.toUpperCase(), width),
                      _detailRow('Status', u.status.toUpperCase(), width),
                      if (u.phone.isNotEmpty) _detailRow('Phone', u.phone, width),
                      if (u.country.isNotEmpty)
                        _detailRow('Country', u.country, width),
                      _detailRow('Total Bookings', u.totalBookings.toString(), width),
                      _detailRow('Total Spent',
                          '\$${u.totalSpent.toStringAsFixed(2)}', width),
                      if (u.createdAt != null)
                        _detailRow(
                          'Joined',
                          '${u.createdAt!.day}/${u.createdAt!.month}/${u.createdAt!.year}',
                          width,
                        ),
                      SizedBox(height: height * 0.03),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (u.email.isNotEmpty) {
                                  final uri = Uri.parse('mailto:${u.email}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              },
                              icon: const Icon(Icons.email),
                              label: const Text('Email'),
                            ),
                          ),
                          SizedBox(width: width * 0.03),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (u.phone.isNotEmpty) {
                                  final uri = Uri.parse('tel:${u.phone}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width * 0.32,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: width * 0.032)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.032,
                    color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }
}