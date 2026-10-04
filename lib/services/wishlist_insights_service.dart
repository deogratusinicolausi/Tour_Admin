import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistInsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 1. POPULARITY MAP — {itemId: likes count}
  // ============================================================
  Future<Map<String, int>> getPopularityMap() async {
    try {
      final snapshot = await _firestore.collection('wishlists').get();
      final map = <String, int>{};

      for (var doc in snapshot.docs) {
        final itemId = (doc.data()['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;
        map[itemId] = (map[itemId] ?? 0) + 1;
      }

      return map;
    } catch (e) {
      print('🔥 Error getting popularity: $e');
      return {};
    }
  }

  // ============================================================
  // 2. TRENDING ITEMS — most liked this week
  // ============================================================
  Future<List<Map<String, dynamic>>> getTrendingItems({
    int limit = 10,
    int days = 7,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('wishlists')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      final grouped = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemId = (data['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;

        if (!grouped.containsKey(itemId)) {
          grouped[itemId] = {
            'itemId': itemId,
            'itemName': data['itemName'] ?? '',
            'itemType': data['itemType'] ?? '',
            'itemImage': data['itemImage'] ?? '',
            'likes': 0,
          };
        }
        grouped[itemId]!['likes'] = (grouped[itemId]!['likes'] as int) + 1;
      }

      final list = grouped.values.toList()
        ..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

      return list.take(limit).toList();
    } catch (e) {
      print('🔥 Error getting trending: $e');
      return [];
    }
  }

  // ============================================================
  // 3. CATEGORY BREAKDOWN — likes per itemType
  // ============================================================
  Future<Map<String, int>> getCategoryBreakdown() async {
    try {
      final snapshot = await _firestore.collection('wishlists').get();
      final map = <String, int>{};

      for (var doc in snapshot.docs) {
        final type = (doc.data()['itemType'] ?? '').toString();
        if (type.isEmpty) continue;
        map[type] = (map[type] ?? 0) + 1;
      }

      return map;
    } catch (e) {
      print('🔥 Error getting categories: $e');
      return {};
    }
  }

  // ============================================================
  // 4. TOP LIKED ITEMS — Top N items with details
  // ============================================================
  Future<List<Map<String, dynamic>>> getTopLikedItems({int limit = 20}) async {
    try {
      final snapshot = await _firestore.collection('wishlists').get();

      final grouped = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemId = (data['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;

        if (!grouped.containsKey(itemId)) {
          grouped[itemId] = {
            'itemId': itemId,
            'itemName': data['itemName'] ?? '',
            'itemType': data['itemType'] ?? '',
            'itemImage': data['itemImage'] ?? '',
            'likes': 0,
          };
        }
        grouped[itemId]!['likes'] = (grouped[itemId]!['likes'] as int) + 1;
      }

      final list = grouped.values.toList()
        ..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

      return list.take(limit).toList();
    } catch (e) {
      print('🔥 Error getting top liked: $e');
      return [];
    }
  }

  // ============================================================
  // 5. WEEKLY TREND — likes per day (last 7 days)
  // ============================================================
  Future<List<Map<String, dynamic>>> getWeeklyLikeTrend() async {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('wishlists')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();

      final days = <String, int>{};
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.day}/${d.month}';
        days[key] = 0;
      }

      for (var doc in snapshot.docs) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final d = ts.toDate();
        final key = '${d.day}/${d.month}';
        if (days.containsKey(key)) {
          days[key] = (days[key] ?? 0) + 1;
        }
      }

      return days.entries
          .map((e) => {'day': e.key, 'likes': e.value})
          .toList();
    } catch (e) {
      print('🔥 Error getting weekly trend: $e');
      return [];
    }
  }

  // ============================================================
  // 6. TOTAL STATS — for admin overview
  // ============================================================
  Future<Map<String, dynamic>> getTotalStats() async {
    try {
      final snapshot = await _firestore.collection('wishlists').get();
      final totalLikes = snapshot.docs.length;

      final uniqueUsers = <String>{};
      final uniqueItems = <String>{};
      final categories = <String, int>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = (data['userId'] ?? '').toString();
        final itemId = (data['itemId'] ?? '').toString();
        final type = (data['itemType'] ?? '').toString();

        if (userId.isNotEmpty) uniqueUsers.add(userId);
        if (itemId.isNotEmpty) uniqueItems.add(itemId);
        if (type.isNotEmpty) categories[type] = (categories[type] ?? 0) + 1;
      }

      // Top category
      String topCategory = 'N/A';
      int topCategoryCount = 0;
      categories.forEach((k, v) {
        if (v > topCategoryCount) {
          topCategory = k;
          topCategoryCount = v;
        }
      });

      final avgLikesPerItem = uniqueItems.isNotEmpty
          ? totalLikes / uniqueItems.length
          : 0.0;

      return {
        'totalLikes': totalLikes,
        'uniqueUsers': uniqueUsers.length,
        'uniqueItems': uniqueItems.length,
        'avgLikesPerItem': avgLikesPerItem,
        'topCategory': topCategory,
        'topCategoryCount': topCategoryCount,
        'categories': categories,
      };
    } catch (e) {
      print('🔥 Error getting total stats: $e');
      return {
        'totalLikes': 0,
        'uniqueUsers': 0,
        'uniqueItems': 0,
        'avgLikesPerItem': 0.0,
        'topCategory': 'N/A',
        'topCategoryCount': 0,
        'categories': {},
      };
    }
  }

  // ============================================================
  // BONUS: TYPE COLOR
  // ============================================================
  String getTypeIcon(String type) {
    switch (type) {
      case 'destination':
        return '📍';
      case 'hotel':
        return '🏨';
      case 'tour':
        return '🦁';
      case 'mountain':
        return '⛰️';
      case 'beach':
        return '🏖️';
      case 'culture':
        return '🎭';
      case 'food':
        return '🍛';
      case 'deal':
        return '🎁';
      default:
        return '❤️';
    }
  }

  // ============================================================
  // LIVE STREAMS
  // ============================================================

  // 1. LIVE POPULARITY MAP — updates on every wishlist change
  Stream<Map<String, int>> streamPopularityMap() {
    return _firestore.collection('wishlists').snapshots().map((snapshot) {
      final map = <String, int>{};
      for (var doc in snapshot.docs) {
        final itemId = (doc.data()['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;
        map[itemId] = (map[itemId] ?? 0) + 1;
      }
      return map;
    });
  }

  // 2. LIVE TOTAL STATS
  Stream<Map<String, dynamic>> streamTotalStats() {
    return _firestore.collection('wishlists').snapshots().map((snapshot) {
      final totalLikes = snapshot.docs.length;
      final uniqueUsers = <String>{};
      final uniqueItems = <String>{};
      final categories = <String, int>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = (data['userId'] ?? '').toString();
        final itemId = (data['itemId'] ?? '').toString();
        final type = (data['itemType'] ?? '').toString();

        if (userId.isNotEmpty) uniqueUsers.add(userId);
        if (itemId.isNotEmpty) uniqueItems.add(itemId);
        if (type.isNotEmpty) categories[type] = (categories[type] ?? 0) + 1;
      }

      String topCategory = 'N/A';
      int topCategoryCount = 0;
      categories.forEach((k, v) {
        if (v > topCategoryCount) {
          topCategory = k;
          topCategoryCount = v;
        }
      });

      final avgLikesPerItem = uniqueItems.isNotEmpty
          ? totalLikes / uniqueItems.length
          : 0.0;

      return {
        'totalLikes': totalLikes,
        'uniqueUsers': uniqueUsers.length,
        'uniqueItems': uniqueItems.length,
        'avgLikesPerItem': avgLikesPerItem,
        'topCategory': topCategory,
        'topCategoryCount': topCategoryCount,
        'categories': categories,
      };
    });
  }

  // 3. LIVE CATEGORY BREAKDOWN
  Stream<Map<String, int>> streamCategoryBreakdown() {
    return _firestore.collection('wishlists').snapshots().map((snapshot) {
      final map = <String, int>{};
      for (var doc in snapshot.docs) {
        final type = (doc.data()['itemType'] ?? '').toString();
        if (type.isEmpty) continue;
        map[type] = (map[type] ?? 0) + 1;
      }
      return map;
    });
  }

  // 4. LIVE TOP LIKED ITEMS
  Stream<List<Map<String, dynamic>>> streamTopLikedItems({int limit = 20}) {
    return _firestore.collection('wishlists').snapshots().map((snapshot) {
      final grouped = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemId = (data['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;

        if (!grouped.containsKey(itemId)) {
          grouped[itemId] = {
            'itemId': itemId,
            'itemName': data['itemName'] ?? '',
            'itemType': data['itemType'] ?? '',
            'itemImage': data['itemImage'] ?? '',
            'likes': 0,
          };
        }
        grouped[itemId]!['likes'] = (grouped[itemId]!['likes'] as int) + 1;
      }

      final list = grouped.values.toList()
        ..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

      return list.take(limit).toList();
    });
  }

  // 5. LIVE TRENDING THIS WEEK
  Stream<List<Map<String, dynamic>>> streamTrendingItems({
    int limit = 10,
    int days = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collection('wishlists')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snapshot) {
      final grouped = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemId = (data['itemId'] ?? '').toString();
        if (itemId.isEmpty) continue;

        if (!grouped.containsKey(itemId)) {
          grouped[itemId] = {
            'itemId': itemId,
            'itemName': data['itemName'] ?? '',
            'itemType': data['itemType'] ?? '',
            'itemImage': data['itemImage'] ?? '',
            'likes': 0,
          };
        }
        grouped[itemId]!['likes'] = (grouped[itemId]!['likes'] as int) + 1;
      }

      final list = grouped.values.toList()
        ..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

      return list.take(limit).toList();
    });
  }

  // 6. LIVE RECENT LIKES — for "live feed"
  Stream<List<Map<String, dynamic>>> streamRecentLikes({int limit = 20}) {
    return _firestore
        .collection('wishlists')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // 7. LIVE WEEKLY TREND — likes per day (last 7 days)
  Stream<List<Map<String, dynamic>>> streamWeeklyLikeTrend() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));

    return _firestore
        .collection('wishlists')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snapshot) {
      final days = <String, int>{};
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.day}/${d.month}';
        days[key] = 0;
      }

      for (var doc in snapshot.docs) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final d = ts.toDate();
        final key = '${d.day}/${d.month}';
        if (days.containsKey(key)) {
          days[key] = (days[key] ?? 0) + 1;
        }
      }

      return days.entries
          .map((e) => {'day': e.key, 'likes': e.value})
          .toList();
    });
  }

  // ============================================================
  // 8. USERS WHO LIKED AN ITEM
  // ============================================================
  Future<List<Map<String, dynamic>>> getUsersWhoLiked(String itemId) async {
    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .where('itemId', isEqualTo: itemId)
          .get();

      final users = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = (data['userId'] ?? '').toString();
        if (userId.isEmpty) continue;

        // Fetch user details
        try {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data() ?? {};

          users.add({
            'userId': userId,
            'userName': userData['name'] ??
                userData['displayName'] ??
                'Unknown User',
            'userEmail': userData['email'] ?? '',
            'userImage': userData['photoUrl'] ?? userData['imageUrl'] ?? '',
            'likedAt': data['createdAt'],
          });
        } catch (e) {
          users.add({
            'userId': userId,
            'userName': 'Unknown User',
            'userEmail': '',
            'userImage': '',
            'likedAt': data['createdAt'],
          });
        }
      }

      // Sort by likedAt desc
      users.sort((a, b) {
        final aTs = a['likedAt'] as Timestamp?;
        final bTs = b['likedAt'] as Timestamp?;
        if (aTs == null || bTs == null) return 0;
        return bTs.compareTo(aTs);
      });

      return users;
    } catch (e) {
      print('🔥 Error getting users: $e');
      return [];
    }
  }
}