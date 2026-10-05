import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post_model.dart';
import '../models/feed_comment_model.dart';

class FeedAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐ Get ALL posts (hidden + visible) — sorted newest first
  Stream<List<FeedPostModel>> getAllPosts() {
    return _firestore
        .collection('feed_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FeedPostModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐ Get only reported posts (moderation queue)
  Stream<List<FeedPostModel>> getReportedPosts() {
    return _firestore
        .collection('feed_posts')
        .where('reportsCount', isGreaterThan: 0)
        .orderBy('reportsCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FeedPostModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐ Get hidden posts
  Stream<List<FeedPostModel>> getHiddenPosts() {
    return _firestore
        .collection('feed_posts')
        .where('isHidden', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FeedPostModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐ Hide post
  Future<bool> hidePost(String postId, String reason) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'isHidden': true,
        'hiddenReason': reason,
        'hiddenAt': FieldValue.serverTimestamp(),
        'hiddenBy': 'admin',
      });

      // Log activity
      await _firestore.collection('activities').add({
        'type': 'feed',
        'action': 'hidden',
        'title': 'Post Hidden',
        'description': 'Post was hidden. Reason: $reason',
        'itemId': postId,
        'itemType': 'feed_post',
        'icon': '🚫',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 hidePost: $e');
      return false;
    }
  }

  // ⭐ Unhide post
  Future<bool> unhidePost(String postId) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'isHidden': false,
        'hiddenReason': '',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐ Delete post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).delete();

      await _firestore.collection('activities').add({
        'type': 'feed',
        'action': 'deleted',
        'title': 'Post Deleted',
        'description': 'Post was permanently deleted',
        'itemId': postId,
        'itemType': 'feed_post',
        'icon': '🗑️',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐ Clear reports (admin ame-review, si kitu mbaya)
  Future<bool> clearReports(String postId) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'reportsCount': 0,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐ Get stats for dashboard
  Future<Map<String, int>> getFeedStats() async {
    try {
      final all = await _firestore.collection('feed_posts').limit(500).get();

      int total = all.docs.length;
      int hidden = 0;
      int reported = 0;

      for (var doc in all.docs) {
        final data = doc.data();
        if (data['isHidden'] == true) hidden++;
        if ((data['reportsCount'] ?? 0) > 0) reported++;
      }

      return {
        'total': total,
        'hidden': hidden,
        'reported': reported,
      };
    } catch (e) {
      print('🔥 getFeedStats: $e');
      return {'total': 0, 'hidden': 0, 'reported': 0};
    }
  }

  // ═══ Comments moderation ═══

  // Get ALL comments for a post (including hidden)
  Stream<List<FeedCommentModel>> getAllComments(String postId) {
    return _firestore
        .collection('feed_posts')
        .doc(postId)
        .collection('comments')
        .limit(200)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => FeedCommentModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<bool> hideComment(String postId, String commentId, String reason) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'isHidden': true,
        'hiddenReason': reason,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unhideComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'isHidden': false,
        'hiddenReason': '',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      await _firestore.collection('feed_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}