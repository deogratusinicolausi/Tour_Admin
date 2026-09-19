import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_settings_model.dart';

class AdminProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ⭐️ Get admin profile
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
      await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return {'uid': doc.id, ...doc.data()!};
    } catch (e) {
      print('🔥 Error getting profile: $e');
      return null;
    }
  }

  // ⭐️ Update admin profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String bio,
    required String country,
    required String city,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'phone': phone,
        'bio': bio,
        'country': country,
        'city': city,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 Error updating profile: $e');
      return false;
    }
  }

  // ⭐️ Update profile photo
  Future<bool> updatePhoto(String photoUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.updatePhotoURL(photoUrl);
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('🔥 Error changing password: $e');
      return false;
    }
  }

  // ⭐️ Send password reset email
  Future<bool> sendPasswordReset() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      await _auth.sendPasswordResetEmail(email: user.email!);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get admin settings
  Future<AdminSettingsModel> getSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AdminSettingsModel();

      final doc = await _firestore
          .collection('admin_settings')
          .doc(user.uid)
          .get();

      if (!doc.exists) return AdminSettingsModel();

      return AdminSettingsModel.fromMap(
          doc.data() as Map<String, dynamic>);
    } catch (e) {
      return AdminSettingsModel();
    }
  }

  // ⭐️ Save admin settings
  Future<bool> saveSettings(AdminSettingsModel settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('admin_settings')
          .doc(user.uid)
          .set(settings.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get admin stats
  Future<Map<String, int>> getAdminStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final activitiesCount = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: user.uid)
          .get();

      final bookingsConfirmed = await _firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: 'confirmed')
          .get();

      final reviewsReplied = await _firestore
          .collection('reviews')
          .where('adminReply', isNotEqualTo: '')
          .get();

      return {
        'activities': activitiesCount.docs.length,
        'bookings': bookingsConfirmed.docs.length,
        'replies': reviewsReplied.docs.length,
      };
    } catch (e) {
      return {};
    }
  }
}