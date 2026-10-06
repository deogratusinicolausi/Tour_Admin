import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post_model.dart';
import '../models/feed_comment_model.dart';

class FeedAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════
  // ⭐ POSTS — GET
  // ═══════════════════════════════════════════

  // Get ALL posts (kwa moderation)
  Stream<List<FeedPostModel>> getAllPosts({int limit = 100}) {
    return _firestore
        .collection('feed_posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
        .map((d) => FeedPostModel.fromMap(d.data(), d.id))
        .toList());
  }

  // Get REPORTED posts
  Stream<List<FeedPostModel>> getReportedPosts() {
    return _firestore
        .collection('feed_posts')
        .where('reportsCount', isGreaterThan: 0)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => FeedPostModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.reportsCount.compareTo(a.reportsCount));
      return list;
    });
  }

  // Get HIDDEN posts
  Stream<List<FeedPostModel>> getHiddenPosts() {
    return _firestore
        .collection('feed_posts')
        .where('isHidden', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
        .map((d) => FeedPostModel.fromMap(d.data(), d.id))
        .toList());
  }

  // Get TOP posts (by likes)
  Stream<List<FeedPostModel>> getTopPosts({int limit = 20}) {
    return _firestore
        .collection('feed_posts')
        .where('isHidden', isEqualTo: false)
        .orderBy('likesCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
        .map((d) => FeedPostModel.fromMap(d.data(), d.id))
        .toList());
  }

  // Get TRENDING posts (by views)
  Stream<List<FeedPostModel>> getTrendingPosts({int limit = 20}) {
    return _firestore
        .collection('feed_posts')
        .where('isHidden', isEqualTo: false)
        .orderBy('viewsCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
        .map((d) => FeedPostModel.fromMap(d.data(), d.id))
        .toList());
  }

  // ═══════════════════════════════════════════
  // ⭐ POSTS — ACTIONS
  // ═══════════════════════════════════════════

  // Hide post
  Future<bool> hidePost(String postId, String reason) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'isHidden': true,
        'hiddenReason': reason,
        'hiddenAt': FieldValue.serverTimestamp(),
        'hiddenBy': 'admin',
      });

      // Log activity
      await _firestore.collection('admin_activities').add({
        'type': 'feed',
        'action': 'hidden',
        'title': 'Post Hidden',
        'description': 'Post hidden. Reason: $reason',
        'itemId': postId,
        'itemType': 'feed_post',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 hidePost: $e');
      return false;
    }
  }

  // Unhide post
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

  // Delete post
  Future<bool> deletePost(String postId) async {
    try {
      // Delete comments subcollection
      final commentsSnap = await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .get();
      for (var doc in commentsSnap.docs) {
        await doc.reference.delete();
      }

      // Delete likes subcollection
      final likesSnap = await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('likes')
          .get();
      for (var doc in likesSnap.docs) {
        await doc.reference.delete();
      }

      // Delete views subcollection
      final viewsSnap = await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('views')
          .get();
      for (var doc in viewsSnap.docs) {
        await doc.reference.delete();
      }

      // Delete post
      await _firestore.collection('feed_posts').doc(postId).delete();

      // Log
      await _firestore.collection('admin_activities').add({
        'type': 'feed',
        'action': 'deleted',
        'title': 'Post Deleted',
        'itemId': postId,
        'itemType': 'feed_post',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('🔥 deletePost: $e');
      return false;
    }
  }

  // Clear reports
  Future<bool> clearReports(String postId) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'reportsCount': 0,
      });

      // Delete reports
      final reportsSnap = await _firestore
          .collection('feed_reports')
          .where('postId', isEqualTo: postId)
          .get();
      for (var doc in reportsSnap.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Feature post (kwa admin mark featured)
  Future<bool> toggleFeatured(String postId, bool featured) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'isFeatured': featured,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // ⭐ COMMENTS — MODERATION
  // ═══════════════════════════════════════════

  // Get ALL comments kwa post
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

  // Get ALL comments across all posts (kwa global moderation)
  Stream<List<Map<String, dynamic>>> getRecentComments({int limit = 100}) {
    return _firestore
        .collectionGroup('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) {
      final data = d.data();
      data['postId'] = d.reference.parent.parent?.id ?? '';
      data['commentId'] = d.id;
      return data;
    }).toList());
  }

  // Hide comment
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

  // Unhide comment
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

  // Delete comment
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

  // ═══════════════════════════════════════════
  // ⭐ REPORTS
  // ═══════════════════════════════════════════

  Stream<List<Map<String, dynamic>>> getAllReports({int limit = 100}) {
    return _firestore
        .collection('feed_reports')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ═══════════════════════════════════════════
  // ⭐ STATS — ANALYTICS
  // ═══════════════════════════════════════════

  // ⭐ Get unique views count kwa post
  Future<int> getUniqueViewsCount(String postId) async {
    try {
      final snap = await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('views')
          .get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ⭐ Get all viewers kwa post (kwa admin kuona nani ameview)
  Stream<List<Map<String, dynamic>>> getPostViewers(String postId) {
    return _firestore
        .collection('feed_posts')
        .doc(postId)
        .collection('views')
        .snapshots()
        .map((s) => s.docs.map((d) => {
              'userId': d.id,
              ...d.data(),
            }).toList());
  }

  Future<Map<String, int>> getFeedStats() async {
    try {
      final all = await _firestore.collection('feed_posts').limit(1000).get();

      int total = all.docs.length;
      int hidden = 0;
      int reported = 0;
      int videos = 0;
      int images = 0;
      int totalLikes = 0;
      int totalComments = 0;
      int totalViews = 0;
      int totalShares = 0;

      for (var doc in all.docs) {
        final data = doc.data();
        if (data['isHidden'] == true) hidden++;
        if ((data['reportsCount'] ?? 0) > 0) reported++;
        if (data['mediaType'] == 'video') {
          videos++;
        } else {
          images++;
        }
        totalLikes += (data['likesCount'] ?? 0) as int;
        totalComments += (data['commentsCount'] ?? 0) as int;
        totalViews += (data['viewsCount'] ?? 0) as int;
        totalShares += (data['sharesCount'] ?? 0) as int;
      }

      return {
        'total': total,
        'hidden': hidden,
        'reported': reported,
        'videos': videos,
        'images': images,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'totalViews': totalViews,
        'totalShares': totalShares,
      };
    } catch (e) {
      print('🔥 getFeedStats: $e');
      return {};
    }
  }
}