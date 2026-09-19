import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Get all coupons
  Stream<List<CouponModel>> getAllCoupons() {
    return _firestore
        .collection('coupons')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CouponModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // ⭐️ Get coupon stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _firestore.collection('coupons').get();

      int active = 0;
      int expired = 0;
      int totalUsage = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? true;
        final endDate = (data['endDate'] as Timestamp?)?.toDate();
        final usedCount = data['usedCount'] ?? 0;

        if (isActive && (endDate == null || endDate.isAfter(DateTime.now()))) {
          active++;
        } else {
          expired++;
        }
        totalUsage += usedCount as int;
      }

      return {
        'total': snapshot.docs.length,
        'active': active,
        'expired': expired,
        'totalUsage': totalUsage,
      };
    } catch (e) {
      return {'total': 0, 'active': 0, 'expired': 0, 'totalUsage': 0};
    }
  }

  // ⭐️ Add coupon
  Future<String?> addCoupon(CouponModel coupon) async {
    try {
      // Check if code exists
      final existing = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: coupon.code.toUpperCase())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Coupon code already exists');
      }

      final ref = await _firestore
          .collection('coupons')
          .add(coupon.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error adding coupon: $e');
      throw e;
    }
  }

  // ⭐️ Update coupon
  Future<bool> updateCoupon(CouponModel coupon) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(coupon.id)
          .update(coupon.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Delete coupon
  Future<bool> deleteCoupon(String couponId) async {
    try {
      await _firestore.collection('coupons').doc(couponId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Toggle active
  Future<bool> toggleActive(String couponId, bool isActive) async {
    try {
      await _firestore.collection('coupons').doc(couponId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get coupon by code
  Future<CouponModel?> getByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return CouponModel.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      return null;
    }
  }
}