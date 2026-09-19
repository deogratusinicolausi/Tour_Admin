import 'package:flutter/material.dart';
import '../models/user_model2.dart';
import '../services/user_service.dart';
import '../utils/colors.dart';
import '../widgets/user_card_widget.dart';
import 'admin_user_detail_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = UserService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterStatus = 'all';
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _service.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filter(List<UserModel> all) {
    return all.where((u) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(search) ||
          u.email.toLowerCase().contains(search) ||
          u.phone.toLowerCase().contains(search);

      final matchRole = _filterRole == 'all' || u.role == _filterRole;
      final matchStatus =
          _filterStatus == 'all' || u.status == _filterStatus;

      return matchSearch && matchRole && matchStatus;
    }).toList();
  }

  Future<void> _changeRole(UserModel user) async {
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _buildRoleSheet(user),
    );

    if (role != null && role != user.role) {
      final ok = await _service.updateRole(user.uid, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ok ? '${context.tr('role_changed')} $role' : context.tr('failed_to_change_role')),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadStats();
      }
    }
  }

  Future<void> _toggleBan(UserModel user) async {
    final isBanned = user.status == 'banned';

    if (isBanned) {
      final ok = await _service.unbanUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(ok ? context.tr('user_unbanned') : context.tr('failed')),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadStats();
      }
    } else {
      final reasonController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.tr('ban_user_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${context.tr('ban')} ${user.name}?'),
              const SizedBox(height: 15),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: context.tr('reason'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ban'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final ok = await _service.banUser(
          user.uid,
          reasonController.text.trim().isEmpty
              ? 'Violated terms'
              : reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? context.tr('user_banned') : context.tr('failed')),
              backgroundColor: ok ? Colors.orange : Colors.red,
            ),
          );
          _loadStats();
        }
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_user_title')),
        content: Text('${context.tr('delete_confirm')} ${user.name}?'),
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
      final ok = await _service.deleteUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? context.tr('user_deleted') : context.tr('failed')),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
        _loadStats();
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
        title: Text(context.tr('users_management')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // STATS
          _buildStats(width, height),

          // SEARCH
          Container(
            padding: EdgeInsets.all(width * 0.04),
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
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: context.textSecondary),
                  hintText: 'Search users by name, email, phone...',
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

          // FILTERS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.008),
            color: AppColors.primary,
            child: Column(
              children: [
                // Role filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'customer', 'admin', 'superAdmin']
                        .map((role) {
                      final isSelected = _filterRole == role;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _filterRole = role),
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
                            role == 'all'
                                ? '👥 All Roles'
                                : context.tr(role).toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: width * 0.024,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: height * 0.005),
                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'active', 'banned', 'suspended']
                        .map((status) {
                      final isSelected = _filterStatus == status;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _filterStatus = status),
                        child: Container(
                          margin: EdgeInsets.only(right: width * 0.02),
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.035,
                              vertical: height * 0.006),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.cardBg
                                : context.cardBg.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            status == 'all'
                                ? '🔔 All Status'
                                : status.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: width * 0.024,
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
              stream: _service.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = _filter(snapshot.data ?? []);

                if (users.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: users.length,
                  itemBuilder: (context, i) => UserCard(
                    user: users[i],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminUserDetailScreen(user: users[i]),
                        ),
                      );
                      _loadStats();
                    },
                    onChangeRole: () => _changeRole(users[i]),
                    onBan: () => _toggleBan(users[i]),
                    onDelete: () => _deleteUser(users[i]),
                  ),
                );
              },
            ),
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
              _bigStat('👥', '${_stats['total'] ?? 0}', context.tr('total_users'),
                  width),
              _bigStat('👤', '${_stats['customers'] ?? 0}', context.tr('customers'),
                  width),
              _bigStat('👑', '${_stats['admins'] ?? 0}', context.tr('admins'), width),
            ],
          ),
          SizedBox(height: height * 0.01),
          Row(
            children: [
              _bigStat('✅', '${_stats['active'] ?? 0}', context.tr('active'), width),
              _bigStat('🚫', '${_stats['banned'] ?? 0}', context.tr('banned'), width),
              _bigStat('🆕', '${_stats['newThisMonth'] ?? 0}', 'New', width),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigStat(
      String icon, String value, String label, double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.02, vertical: width * 0.025),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: width * 0.05)),
            SizedBox(height: width * 0.005),
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

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: width * 0.2, color: context.textSecondary.withOpacity(0.3)),
          SizedBox(height: height * 0.02),
          Text(
            context.tr('no_users_found'),
            style: TextStyle(
              fontSize: width * 0.05,
              color: context.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSheet(UserModel user) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: width * 0.05),
          Text(
            '${context.tr('change_role_for')} ${user.name}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          SizedBox(height: width * 0.03),
          _roleOption('customer', '👤', context.tr('customer'), context.tr('regular_user_desc'),
              Colors.blue, user.role, width),
          _roleOption('admin', '🛡️', context.tr('admin'), context.tr('admin_desc'),
              AppColors.accentGold, user.role, width),
          _roleOption('superAdmin', '👑', context.tr('superAdmin'), context.tr('super_admin_desc'),
              Colors.red, user.role, width),
          SizedBox(height: width * 0.03),
        ],
      ),
    );
  }

  Widget _roleOption(String role, String emoji, String title, String desc,
      Color color, String currentRole, double width) {
    final isCurrent = currentRole == role;
    return GestureDetector(
      onTap: () => Navigator.pop(context, role),
      child: Container(
        margin: EdgeInsets.only(bottom: width * 0.02),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: isCurrent ? color.withOpacity(0.1) : context.pageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? color : context.textSecondary.withOpacity(0.1),
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
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
                  Text(desc,
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 12)),
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
}