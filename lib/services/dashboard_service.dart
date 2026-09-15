import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get total count from collection
  Future<int> getCount(String collection) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.length;
    } catch (e) {
      print('🔥 Error getting $collection count: $e');
      return 0;
    }
  }

  // ⭐️ Get all dashboard stats
  Future<Map<String, int>> getAllStats() async {
    try {
      final results = await Future.wait([
        getCount('users'),
        getCount('bookings'),
        getCount('destinations'),
        getCount('hotels'),
        getCount('tours'),
        getCount('activities'),
        getCount('deals'),
        getCount('beaches'),  // ⭐ ONGEZA
        getCount('mountains'),  // ⭐ ONGEZA
        getCount('culture'),  // ⭐ ONGEZA
        getCount('food'),  // ⭐ ONGEZA
        getCount('reviews'),  // ⭐ ONGEZA
      ]);

      return {
        'users': results[0],
        'bookings': results[1],
        'destinations': results[2],
        'hotels': results[3],
        'tours': results[4],
        'activities': results[5],
        'deals': results[6],
        'beaches': results[7],  // ⭐ ONGEZA
        'mountains': results[8],  // ⭐ ONGEZA
        'culture': results[9],  // ⭐ ONGEZA
        'food': results[10],  // ⭐ ONGEZA
        'reviews': results[11],  // ⭐ ONGEZA
      };
    } catch (e) {
      print('🔥 Error getting stats: $e');
      return {
        'users': 0,
        'bookings': 0,
        'destinations': 0,
        'hotels': 0,
        'tours': 0,
        'activities': 0,
        'deals': 0,
      };
    }
  }

  // ⭐️ Get pending bookings
  Future<int> getPendingBookings() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ⭐️ Get confirmed bookings
  Future<int> getConfirmedBookings() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('bookingStatus', isEqualTo: 'confirmed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ⭐️ Get recent bookings (last 5)
  Future<List<Map<String, dynamic>>> getRecentBookings() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'itemName': data['itemName'] ?? 'Unknown',
          'userName': data['userName'] ?? 'Guest',
          'amount': data['amount'] ?? 0,
          'status': data['bookingStatus'] ?? 'pending',
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('🔥 Error getting recent bookings: $e');
      return [];
    }
  }

  // ⭐️ Get recent destinations
  Future<List<Map<String, dynamic>>> getRecentDestinations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('destinations')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'country': data['country'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('🔥 Error getting recent destinations: $e');
      return [];
    }
  }

  // ⭐️ Get bookings for last 7 days
  Future<List<Map<String, dynamic>>> getBookingsLast7Days() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day - i);
        final nextDay = day.add(const Duration(days: 1));

        final snapshot = await _firestore
            .collection('bookings')
            .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(day))
            .where('createdAt', isLessThan: Timestamp.fromDate(nextDay))
            .get();

        result.add({
          'day': _getDayName(day.weekday),
          'date': '${day.day}/${day.month}',
          'count': snapshot.docs.length,
        });
      }

      return result;
    } catch (e) {
      print('🔥 Error getting bookings last 7 days: $e');
      return [];
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ⭐️ Get revenue by month
  Future<List<Map<String, dynamic>>> getRevenueByMonth() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);

        final snapshot = await _firestore
            .collection('bookings')
            .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(month))
            .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
            .where('bookingStatus', whereIn: ['confirmed', 'completed'])
            .get();

        double revenue = 0;
        for (var doc in snapshot.docs) {
          revenue += ((doc.data())['amount'] ?? 0.0).toDouble();
        }

        result.add({
          'month': _getMonthName(month.month),
          'revenue': revenue,
        });
      }

      return result;
    } catch (e) {
      print('🔥 Error getting revenue by month: $e');
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

  // ⭐️ Get item type distribution
  Future<Map<String, int>> getItemTypeDistribution() async {
    try {
      final snapshot = await _firestore.collection('bookings').get();
      Map<String, int> result = {
        'hotel': 0,
        'tour': 0,
        'activity': 0,
        'deal': 0,
      };

      for (var doc in snapshot.docs) {
        final type = (doc.data())['itemType'] ?? 'tour';
        result[type] = (result[type] ?? 0) + 1;
      }

      return result;
    } catch (e) {
      return {'hotel': 0, 'tour': 0, 'activity': 0, 'deal': 0};
    }
  }
}