import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get total count from collection
  Future<int> getCount(String collection) async {
    try {
      final snapshot =
          await _firestore.collection(collection).limit(500).get();
      return snapshot.docs.length;
    } catch (e) {
      print('🔥 getCount($collection): $e');
      return 0;
    }
  }

  // ⭐ All stats (FIXED — same shape on success & failure)
  Future<Map<String, int>> getAllStats() async {
    // Safe defaults — all keys always present
    final defaults = {
      'users': 0,
      'bookings': 0,
      'destinations': 0,
      'hotels': 0,
      'tours': 0,
      'activities': 0,
      'deals': 0,
      'beaches': 0,
      'mountains': 0,
      'culture': 0,
      'food': 0,
      'reviews': 0,
    };

    try {
      final results = await Future.wait([
        getCount('users'),
        getCount('bookings'),
        getCount('destinations'),
        getCount('hotels'),
        getCount('tours'),
        getCount('activities'),
        getCount('deals'),
        getCount('beaches'),
        getCount('mountains'),
        getCount('culture'),
        getCount('food'),
        getCount('reviews'),
      ]);

      return {
        'users': results[0],
        'bookings': results[1],
        'destinations': results[2],
        'hotels': results[3],
        'tours': results[4],
        'activities': results[5],
        'deals': results[6],
        'beaches': results[7],
        'mountains': results[8],
        'culture': results[9],
        'food': results[10],
        'reviews': results[11],
      };
    } catch (e) {
      print('🔥 getAllStats: $e');
      return defaults;
    }
  }

  // ⭐ Pending bookings
  Future<int> getPendingBookings() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('🔥 getPendingBookings: $e');
      return 0;
    }
  }

  // ⭐ Confirmed bookings
  Future<int> getConfirmedBookings() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: 'confirmed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('🔥 getConfirmedBookings: $e');
      return 0;
    }
  }

  // ⭐ Recent bookings (last 5)
  // NOTE: no orderBy — safer, sorts client-side
  Future<List<Map<String, dynamic>>> getRecentBookings() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .limit(50)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'itemName': data['itemName'] ?? 'Unknown',
          'userName': data['userName'] ?? 'Guest',
          'amount': data['amount'] ?? 0,
          'status': data['bookingStatus'] ?? 'pending',
          'createdAt': data['createdAt'],
        };
      }).toList();

      // Sort client-side by createdAt descending
      list.sort((a, b) {
        final aT = a['createdAt'];
        final bT = b['createdAt'];
        if (aT == null || bT == null) return 0;
        try {
          return (bT as dynamic).compareTo(aT as dynamic);
        } catch (_) {
          return 0;
        }
      });

      return list.take(5).toList();
    } catch (e) {
      print('🔥 getRecentBookings: $e');
      return [];
    }
  }

  // ⭐ Recent destinations
  Future<List<Map<String, dynamic>>> getRecentDestinations() async {
    try {
      final snapshot = await _firestore
          .collection('destinations')
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'country': data['country'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('🔥 getRecentDestinations: $e');
      return [];
    }
  }

  // ⭐ Bookings last 7 days — UNIVERSAL parser
  Future<List<Map<String, dynamic>>> getBookingsLast7Days() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final cutoff = startOfDay.subtract(const Duration(days: 6));

      final snapshot =
          await _firestore.collection('bookings').limit(500).get();

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📅 7-DAY DEBUG');
      debugPrint('Cutoff (>= this date): $cutoff');
      debugPrint('Total bookings fetched: ${snapshot.docs.length}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Build 7 buckets
      final days = <String, int>{};
      final dates = <String, String>{};
      for (int i = 6; i >= 0; i--) {
        final day = startOfDay.subtract(Duration(days: i));
        final key = _getDayName(day.weekday);
        days[key] = 0;
        dates[key] = '${day.day}/${day.month}';
      }

      int skipped = 0;
      int matched = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final raw = data['createdAt'];

        // 👇 UNIVERSAL PARSER
        DateTime? created;
        if (raw is Timestamp) {
          created = raw.toDate();
        } else if (raw is String) {
          created = DateTime.tryParse(raw);
        } else if (raw is int) {
          created = DateTime.fromMillisecondsSinceEpoch(raw);
        } else if (raw is Map && raw['seconds'] != null) {
          created = DateTime.fromMillisecondsSinceEpoch(
              (raw['seconds'] as num).toInt() * 1000);
        }

        if (created == null) {
          skipped++;
          if (skipped <= 3) {
            debugPrint('⚠️ Skipped ${doc.id} — createdAt: $raw (${raw.runtimeType})');
          }
          continue;
        }

        if (created.isBefore(cutoff)) continue;

        final key = _getDayName(created.weekday);
        if (days.containsKey(key)) {
          days[key] = (days[key] ?? 0) + 1;
          matched++;
        }
      }

      debugPrint('✅ Matched in last 7 days: $matched');
      debugPrint('⚠️ Skipped (no valid date): $skipped');
      debugPrint('📊 Final buckets: $days');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return days.entries
          .map((e) => {
                'day': e.key,
                'date': dates[e.key] ?? '',
                'count': e.value,
              })
          .toList();
    } catch (e) {
      print('🔥 getBookingsLast7Days: $e');
      return [];
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ⭐ Revenue by month — UNIVERSAL parser
  Future<List<Map<String, dynamic>>> getRevenueByMonth() async {
    try {
      final now = DateTime.now();
      final cutoff = DateTime(now.year, now.month - 5, 1);

      final snapshot =
          await _firestore.collection('bookings').limit(500).get();

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('💰 REVENUE DEBUG');
      debugPrint('Cutoff: $cutoff');
      debugPrint('Total bookings: ${snapshot.docs.length}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final months = <String, double>{};
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        months[_getMonthName(month.month)] = 0;
      }

      int skipped = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Only confirmed/completed
        final status = (data['bookingStatus'] ?? '').toString();
        if (status != 'confirmed' && status != 'completed') continue;

        final raw = data['createdAt'];

        // 👇 UNIVERSAL PARSER
        DateTime? created;
        if (raw is Timestamp) {
          created = raw.toDate();
        } else if (raw is String) {
          created = DateTime.tryParse(raw);
        } else if (raw is int) {
          created = DateTime.fromMillisecondsSinceEpoch(raw);
        } else if (raw is Map && raw['seconds'] != null) {
          created = DateTime.fromMillisecondsSinceEpoch(
              (raw['seconds'] as num).toInt() * 1000);
        }

        if (created == null) {
          skipped++;
          continue;
        }
        if (created.isBefore(cutoff)) continue;

        final key = _getMonthName(created.month);
        if (months.containsKey(key)) {
          months[key] = (months[key] ?? 0) +
              ((data['amount'] ?? 0) as num).toDouble();
        }
      }

      debugPrint('💰 Revenue: $months');
      debugPrint('⚠️ Skipped: $skipped');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return months.entries
          .map((e) => {'month': e.key, 'revenue': e.value})
          .toList();
    } catch (e) {
      print('🔥 getRevenueByMonth: $e');
      return [];
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // ⭐ Item type distribution
  Future<Map<String, int>> getItemTypeDistribution() async {
    try {
      final snapshot =
          await _firestore.collection('bookings').limit(500).get();

      final result = <String, int>{
        'hotel': 0,
        'tour': 0,
        'activity': 0,
        'deal': 0,
        'destination': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = (data['itemType'] ?? 'tour').toString().toLowerCase();
        result[type] = (result[type] ?? 0) + 1;
      }

      return result;
    } catch (e) {
      print('🔥 getItemTypeDistribution: $e');
      return {'hotel': 0, 'tour': 0, 'activity': 0, 'deal': 0};
    }
  }
}