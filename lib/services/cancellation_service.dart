import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cancellation_model.dart';

class CancellationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all cancellations
  Stream<List<CancellationModel>> getAllCancellations() {
    return _firestore
        .collection('cancellations')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CancellationModel.fromMap(doc.data(), doc.id))
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
  Future<Map<String, int>> getGlobalStats() async {
    try {
      final snapshot = await _firestore.collection('cancellations').get();
      int pending = 0, approved = 0, rejected = 0, refunded = 0;
      for (var doc in snapshot.docs) {
        final status = (doc.data())['status'] ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'refunded':
            refunded++;
            break;
        }
      }
      return {
        'total': snapshot.docs.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'refunded': refunded,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'refunded': 0,
      };
    }
  }

  // ⭐️ Approve cancellation
  Future<bool> approveCancellation(String id, String notes) async {
    try {
      final doc =
      await _firestore.collection('cancellations').doc(id).get();
      final data = doc.data()!;

      await _firestore.collection('cancellations').doc(id).update({
        'status': 'approved',
        'adminNotes': notes,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('bookings')
          .doc(data['bookingId'])
          .update({
        'bookingStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('notifications').add({
        'userId': data['userId'],
        'title': '✅ Cancellation Approved',
        'body':
        'Your cancellation for "${data['itemName']}" has been approved.',
        'type': 'cancellation',
        'category': 'success',
        'icon': '✅',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Reject cancellation
  Future<bool> rejectCancellation(String id, String reason) async {
    try {
      final doc =
      await _firestore.collection('cancellations').doc(id).get();
      final data = doc.data()!;

      await _firestore.collection('cancellations').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('bookings')
          .doc(data['bookingId'])
          .update({
        'bookingStatus': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('notifications').add({
        'userId': data['userId'],
        'title': '❌ Cancellation Rejected',
        'body': 'Your cancellation request was rejected: $reason',
        'type': 'cancellation',
        'category': 'error',
        'icon': '❌',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Process refund
  Future<bool> processRefund(String id) async {
    try {
      final doc =
      await _firestore.collection('cancellations').doc(id).get();
      final data = doc.data()!;

      await _firestore.collection('cancellations').doc(id).update({
        'status': 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('refunds').add({
        'cancellationId': id,
        'bookingId': data['bookingId'],
        'userId': data['userId'],
        'userName': data['userName'],
        'amount': data['refundAmount'],
        'currency': data['currency'],
        'status': 'completed',
        'processedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('notifications').add({
        'userId': data['userId'],
        'title': '💰 Refund Processed!',
        'body':
        '${data['currency']} ${(data['refundAmount'] as num).toStringAsFixed(0)} has been refunded.',
        'type': 'refund',
        'category': 'success',
        'icon': '💰',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}