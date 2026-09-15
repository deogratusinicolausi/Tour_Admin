import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all payments (Real-time)
  Stream<List<PaymentModel>> getAllPayments() {
    return _firestore
        .collection('payments')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get payment stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _firestore.collection('payments').get();

      double totalRevenue = 0;
      double pendingAmount = 0;
      double refundedAmount = 0;
      int completed = 0;
      int pending = 0;
      int failed = 0;
      int refunded = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0) as num;
        final status = data['status'] ?? 'pending';

        switch (status) {
          case 'completed':
            completed++;
            totalRevenue += amount;
            break;
          case 'pending':
            pending++;
            pendingAmount += amount;
            break;
          case 'failed':
            failed++;
            break;
          case 'refunded':
            refunded++;
            refundedAmount += amount;
            break;
        }
      }

      return {
        'total': snapshot.docs.length,
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'refundedAmount': refundedAmount,
        'completed': completed,
        'pending': pending,
        'failed': failed,
        'refunded': refunded,
      };
    } catch (e) {
      return {
        'total': 0,
        'totalRevenue': 0.0,
        'pendingAmount': 0.0,
        'refundedAmount': 0.0,
        'completed': 0,
        'pending': 0,
        'failed': 0,
        'refunded': 0,
      };
    }
  }

  // ⭐️ Revenue by last 7 days
  Future<List<Map<String, dynamic>>> getRevenueLast7Days() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day - i);
        final nextDay = day.add(const Duration(days: 1));

        final snapshot = await _firestore
            .collection('payments')
            .where('status', isEqualTo: 'completed')
            .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(day))
            .where('createdAt', isLessThan: Timestamp.fromDate(nextDay))
            .get();

        double revenue = 0;
        for (var doc in snapshot.docs) {
          revenue += ((doc.data())['amount'] ?? 0.0) as num;
        }

        result.add({
          'day': _getDayName(day.weekday),
          'revenue': revenue,
        });
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Revenue by last 6 months
  Future<List<Map<String, dynamic>>> getRevenueLast6Months() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);

        final snapshot = await _firestore
            .collection('payments')
            .where('status', isEqualTo: 'completed')
            .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(month))
            .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
            .get();

        double revenue = 0;
        for (var doc in snapshot.docs) {
          revenue += ((doc.data())['amount'] ?? 0.0) as num;
        }

        result.add({
          'month': _getMonthName(month.month),
          'revenue': revenue,
        });
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Payment methods breakdown
  Future<Map<String, int>> getPaymentMethodsBreakdown() async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'completed')
          .get();

      Map<String, int> result = {
        'cash': 0,
        'mpesa': 0,
        'tigopesa': 0,
        'airtel': 0,
        'bank': 0,
        'card': 0,
      };

      for (var doc in snapshot.docs) {
        final method = (doc.data())['method'] ?? 'cash';
        result[method] = (result[method] ?? 0) + 1;
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  // ⭐️ Top selling items
  Future<List<Map<String, dynamic>>> getTopSellingItems() async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'completed')
          .get();

      Map<String, Map<String, dynamic>> items = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemName = data['itemName'] ?? 'Unknown';
        final itemType = data['itemType'] ?? '';
        final amount = (data['amount'] ?? 0.0) as num;

        if (items.containsKey(itemName)) {
          items[itemName]!['count']++;
          items[itemName]!['revenue'] += amount;
        } else {
          items[itemName] = {
            'name': itemName,
            'type': itemType,
            'count': 1,
            'revenue': amount,
          };
        }
      }

      final list = items.values.toList();
      list.sort((a, b) =>
          (b['revenue'] as num).compareTo(a['revenue'] as num));

      return list.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // ⭐️ Approve payment
  Future<bool> approvePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'completed',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Refund payment
  Future<bool> refundPayment(String paymentId, String reason) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'refunded',
        'refundReason': reason,
        'refundedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete payment
  Future<bool> deletePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}