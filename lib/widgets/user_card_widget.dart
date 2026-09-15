import 'package:flutter/material.dart';
import '../models/user_model2.dart';
import '../utils/colors.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onChangeRole;
  final VoidCallback onBan;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onChangeRole,
    required this.onBan,
    required this.onDelete,
  });

  Color get _roleColor {
    switch (user.role) {
      case 'superAdmin':
        return Colors.red;
      case 'admin':
        return AppColors.accentGold;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isBanned = user.status == 'banned';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isBanned
              ? Border.all(color: Colors.red.withOpacity(0.3), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.08),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: width * 0.07,
                        backgroundColor: _roleColor,
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: user.photoUrl.isEmpty
                            ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.06,
                          ),
                        )
                            : null,
                      ),
                      if (isBanned)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.block,
                                color: Colors.white, size: width * 0.03),
                          ),
                        ),
                    ],
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
                                user.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.04,
                                  color: Colors.grey.shade900,
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BANNED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: height * 0.003),
                        Row(
                          children: [
                            Icon(Icons.email,
                                size: width * 0.03,
                                color: Colors.grey.shade500),
                            SizedBox(width: width * 0.01),
                            Expanded(
                              child: Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: width * 0.028,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.005),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  color: _roleColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: width * 0.02),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.status == 'active'
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.status.toUpperCase(),
                                style: TextStyle(
                                  color: user.status == 'active'
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  _statBox(
                    Icons.calendar_today,
                    '${user.totalBookings}',
                    'Bookings',
                    Colors.blue,
                    width,
                  ),
                  _statBox(
                    Icons.attach_money,
                    '\$${user.totalSpent.toStringAsFixed(0)}',
                    'Spent',
                    Colors.green,
                    width,
                  ),
                  _statBox(
                    Icons.star,
                    '${user.totalReviews}',
                    'Reviews',
                    AppColors.accentGold,
                    width,
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, vertical: height * 0.012),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.visibility,
                      label: 'View',
                      color: AppColors.primary,
                      onTap: onTap,
                      width: width,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.admin_panel_settings,
                      label: 'Role',
                      color: AppColors.accentGold,
                      onTap: onChangeRole,
                      width: width,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: _actionBtn(
                      icon: isBanned ? Icons.lock_open : Icons.block,
                      label: isBanned ? 'Unban' : 'Ban',
                      color: isBanned ? Colors.green : Colors.orange,
                      onTap: onBan,
                      width: width,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: onDelete,
                      width: width,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(
      IconData icon, String value, String label, Color color, double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.02, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: width * 0.045),
            SizedBox(height: width * 0.01),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.032,
                color: Colors.grey.shade900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: width * 0.022,
                color: Colors.grey.shade600,
              ),
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
            Icon(icon, color: color, size: width * 0.035),
            SizedBox(width: width * 0.005),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: width * 0.024,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}