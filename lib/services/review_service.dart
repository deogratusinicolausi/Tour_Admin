import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all reviews
  Stream<List<ReviewModel>> getAllReviews() {
    return _firestore
        .collection('reviews')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get global stats
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final snapshot = await _firestore.collection('reviews').get();

      if (snapshot.docs.isEmpty) {
        return {
          'total': 0,
          'average': 0.0,
          '5': 0,
          '4': 0,
          '3': 0,
          '2': 0,
          '1': 0,
          'verified': 0,
          'withPhotos': 0,
          'replied': 0,
          'featured': 0,
        };
      }

      double sum = 0;
      int star5 = 0, star4 = 0, star3 = 0, star2 = 0, star1 = 0;
      int verified = 0, withPhotos = 0, replied = 0, featured = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0.0) as num;
        sum += rating;
        final rounded = rating.round();
        switch (rounded) {
          case 5:
            star5++;
            break;
          case 4:
            star4++;
            break;
          case 3:
            star3++;
            break;
          case 2:
            star2++;
            break;
          default:
            star1++;
        }
        if (data['verified'] == true) verified++;
        if ((data['photos'] as List?)?.isNotEmpty ?? false) withPhotos++;
        if ((data['adminReply'] ?? '').toString().isNotEmpty) replied++;
        if (data['featured'] == true) featured++;
      }

      return {
        'total': snapshot.docs.length,
        'average': sum / snapshot.docs.length,
        '5': star5,
        '4': star4,
        '3': star3,
        '2': star2,
        '1': star1,
        'verified': verified,
        'withPhotos': withPhotos,
        'replied': replied,
        'featured': featured,
      };
    } catch (e) {
      return {
        'total': 0,
        'average': 0.0,
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
        'verified': 0,
        'withPhotos': 0,
        'replied': 0,
        'featured': 0,
      };
    }
  }

  // ⭐️ Reply to review
  Future<bool> replyToReview(
      String reviewId, String reply) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'adminReply': reply,
        'adminReplyAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ⭐️ Get review to send notification
      final doc = await _firestore.collection('reviews').doc(reviewId).get();
      final data = doc.data();
      if (data != null) {
        final userId = data['userId'] ?? '';

        // Send notification to user
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': '💬 TURIVA Replied to Your Review',
          'body': reply.length > 50 ? '${reply.substring(0, 50)}...' : reply,
          'type': 'review',
          'category': 'info',
          'icon': '💬',
          'actionType': 'open_review',
          'actionId': reviewId,
          'isRead': false,
          'isPushed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Log activity
        await _firestore.collection('activities').add({
          'type': 'review',
          'action': 'replied',
          'title': 'Admin replied to review',
          'description':
          'Replied to ${data['userName']}\'s review of ${data['itemName']}',
          'itemId': reviewId,
          'itemType': 'review',
          'icon': '💬',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('🔥 Error replying: $e');
      return false;
    }
  }

  // ⭐️ Delete reply
  Future<bool> deleteReply(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'adminReply': '',
        'adminReplyAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Toggle featured
  Future<bool> toggleFeatured(String reviewId, bool featured) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Approve review
  Future<bool> approveReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Reject review
  Future<bool> rejectReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get reviews by item
  Stream<List<ReviewModel>> getReviewsByItem(String itemId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐️ Get pending reviews count
  Stream<int> getPendingCount() {
    return _firestore
        .collection('reviews')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}