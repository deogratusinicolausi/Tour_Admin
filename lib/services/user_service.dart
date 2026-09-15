import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model2.dart';


class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get user stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final all = await _firestore.collection('users').get();

      int customers = 0;
      int admins = 0;
      int banned = 0;
      int active = 0;
      int newThisMonth = 0;
      double totalSpent = 0;

      final now = DateTime.now();
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      for (var doc in all.docs) {
        final data = doc.data();
        final role = data['role'] ?? 'customer';
        final status = data['status'] ?? 'active';
        final spent = (data['totalSpent'] ?? 0.0) as num;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        if (role == 'customer') customers++;
        else if (role == 'admin' || role == 'superAdmin') admins++;

        if (status == 'banned') banned++;
        else if (status == 'active') active++;

        totalSpent += spent;

        if (createdAt != null && createdAt.isAfter(monthAgo)) {
          newThisMonth++;
        }
      }

      return {
        'total': all.docs.length,
        'customers': customers,
        'admins': admins,
        'banned': banned,
        'active': active,
        'newThisMonth': newThisMonth,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      return {
        'total': 0,
        'customers': 0,
        'admins': 0,
        'banned': 0,
        'active': 0,
        'newThisMonth': 0,
        'totalSpent': 0.0,
      };
    }
  }

  // ⭐️ Update user role
  Future<bool> updateRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Update user status
  Future<bool> updateStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Ban user
  Future<bool> banUser(String uid, String reason) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'banned',
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _firestore.collection('activities').add({
        'type': 'user',
        'action': 'banned',
        'title': 'User Banned',
        'description': 'User was banned. Reason: $reason',
        'itemId': uid,
        'itemType': 'user',
        'icon': '🚫',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Unban user
  Future<bool> unbanUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'active',
        'banReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete user
  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get user bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .limit(10)
          .get();
      final list = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      list.sort((a, b) {
        final aDate = (a['createdAt'] as Timestamp?)?.toDate() ??
            DateTime(2000);
        final bDate = (b['createdAt'] as Timestamp?)?.toDate() ??
            DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Get user reviews
  Future<List<Map<String, dynamic>>> getUserReviews(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Send notification to user
  Future<void> sendNotification({
    required String uid,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': uid,
        'title': title,
        'body': body,
        'type': 'system',
        'category': 'info',
        'icon': '🔔',
        'isRead': false,
        'isPushed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('🔥 Error sending notification: $e');
    }
  }
}