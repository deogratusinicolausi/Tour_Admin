import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/admin_notification_service.dart';
import '../utils/colors.dart';
import '../widgets/notification_card_widget.dart';
import 'admin_chats_list_screen.dart';
import 'bookings_list_screen.dart';
import 'users_list_screen.dart';
import 'destinations_list_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  final _service = AdminNotificationService();
  String _filter = 'all';

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': '🔔 All'},
    {'value': 'unread', 'label': '🔵 Unread'},
    {'value': 'chat', 'label': '💬 Chats'},
    {'value': 'booking', 'label': '📅 Bookings'},
    {'value': 'order', 'label': '🛒 Orders'},
    {'value': 'review', 'label': '⭐ Reviews'},
    {'value': 'user', 'label': '👥 Users'},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🔔 Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all read',
            onPressed: () async {
              await _service.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ All marked as read'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () => _confirmClear(),
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTERS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _filter == f['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f['value']!),
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
                        f['label']!,
                        style: TextStyle(
                          color:
                          isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.026,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _service.getAdminNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? [];
                final notifications = all.where((n) {
                  if (_filter == 'all') return true;
                  if (_filter == 'unread') return !n.isRead;
                  return n.type == _filter;
                }).toList();

                if (notifications.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: notifications.length,
                  itemBuilder: (context, i) {
                    final notif = notifications[i];
                    return NotificationCard(
                      notification: notif,
                      onTap: () async {
                        if (!notif.isRead) {
                          await _service.markAsRead(notif.id);
                        }
                        _handleAction(notif);
                      },
                      onDelete: () =>
                          _service.deleteNotification(notif.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.1),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none,
                size: width * 0.15, color: AppColors.primary),
          ),
          SizedBox(height: height * 0.03),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            'You\'re all caught up! 🎉',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: width * 0.035,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(NotificationModel notif) {
    Widget? screen;

    switch (notif.actionType) {
      case 'open_chat':
        screen = const AdminChatsListScreen();
        break;
      case 'open_booking':
        screen = const BookingsListScreen();
        break;
      case 'open_user':
        screen = const UsersListScreen();
        break;
      case 'open_destination':
        screen = const DestinationsListScreen();
        break;
    }

    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('Delete all admin notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.clearAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}