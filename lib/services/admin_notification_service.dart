import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'sound_service.dart';

class AdminNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get ALL notifications (Admin view — all users)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐️ Get admin-specific notifications (userId = 'admin')
  Stream<List<NotificationModel>> getAdminNotifications() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: 'admin')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get unread count (Admin)
  Stream<int> getUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ⭐️ Mark as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Clear all admin notifications
  Future<bool> clearAll() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'admin')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Create admin notification
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final ref = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  // ⭐️ LISTEN for NEW notifications → Play sound
  void listenForNewNotifications() {
    bool isFirstLoad = true;
    Set<String> knownIds = {};

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (isFirstLoad) {
        // Store known IDs
        knownIds = snapshot.docs.map((d) => d.id).toSet();
        isFirstLoad = false;
        return;
      }

      // Check for new notifications
      for (var doc in snapshot.docs) {
        if (!knownIds.contains(doc.id)) {
          knownIds.add(doc.id);
          final type = doc.data()['type'] ?? 'system';
          SoundService.playByType(type);
        }
      }
    });
  }

  // ⭐️ Send notification to user
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String icon = '🔔',
    String actionType = '',
    String actionId = '',
  }) async {
    await createNotification(NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      icon: icon,
      actionType: actionType,
      actionId: actionId,
    ));
  }

  // ⭐️ Send notification to admin
  Future<void> sendToAdmin({
    required String title,
    required String body,
    required String type,
    String icon = '🔔',
    String actionType = '',
    String actionId = '',
  }) async {
    await createNotification(NotificationModel(
      id: '',
      userId: 'admin',
      title: title,
      body: body,
      type: type,
      icon: icon,
      actionType: actionType,
      actionId: actionId,
    ));
  }
}