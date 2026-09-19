import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType; // percentage, fixed
  final double discountValue; // 20 for 20%, 50 for $50
  final double minAmount; // Minimum purchase
  final double maxDiscount; // Max discount cap
  final String currency;
  final String applicableTo; // all, hotel, tour, beach, mountain, culture, food, deal
  final List<String> applicableItems; // Specific item IDs
  final int usageLimit; // 0 = unlimited
  final int usedCount;
  final int perUserLimit; // 1 = once per user
  final List<String> usedBy; // User IDs
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String bannerImage;
  final String termsAndConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    this.discountType = 'percentage',
    required this.discountValue,
    this.minAmount = 0.0,
    this.maxDiscount = 0.0,
    this.currency = 'USD',
    this.applicableTo = 'all',
    this.applicableItems = const [],
    this.usageLimit = 0,
    this.usedCount = 0,
    this.perUserLimit = 1,
    this.usedBy = const [],
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.bannerImage = '',
    this.termsAndConditions = '',
    this.createdAt,
    this.updatedAt,
  });

  factory CouponModel.fromMap(Map<String, dynamic> map, String id) {
    return CouponModel(
      id: id,
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] ?? 0.0).toDouble(),
      minAmount: (map['minAmount'] ?? 0.0).toDouble(),
      maxDiscount: (map['maxDiscount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      applicableTo: map['applicableTo'] ?? 'all',
      applicableItems: List<String>.from(map['applicableItems'] ?? []),
      usageLimit: map['usageLimit'] ?? 0,
      usedCount: map['usedCount'] ?? 0,
      perUserLimit: map['perUserLimit'] ?? 1,
      usedBy: List<String>.from(map['usedBy'] ?? []),
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      bannerImage: map['bannerImage'] ?? '',
      termsAndConditions: map['termsAndConditions'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minAmount': minAmount,
      'maxDiscount': maxDiscount,
      'currency': currency,
      'applicableTo': applicableTo,
      'applicableItems': applicableItems,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'perUserLimit': perUserLimit,
      'usedBy': usedBy,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'bannerImage': bannerImage,
      'termsAndConditions': termsAndConditions,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ⭐️ Calculate discount
  double calculateDiscount(double amount) {
    if (amount < minAmount) return 0;

    double discount = 0;
    if (discountType == 'percentage') {
      discount = amount * (discountValue / 100);
      if (maxDiscount > 0 && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else {
      discount = discountValue;
      if (discount > amount) discount = amount;
    }
    return discount;
  }

  // ⭐️ Check if coupon is valid
  bool get isValid {
    if (!isActive) return false;

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (usageLimit > 0 && usedCount >= usageLimit) return false;

    return true;
  }

  // ⭐️ Check if user already used
  bool userUsed(String userId) => usedBy.contains(userId);

  // ⭐️ Check usage limit for user
  bool canUserUse(String userId) {
    if (perUserLimit == 0) return true;
    return !usedBy.contains(userId);
  }

  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '$currency ${discountValue.toStringAsFixed(0)} OFF';
  }

  String get timeAgo {
    if (createdAt == null) return 'just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  String get expiryText {
    if (endDate == null) return 'No expiry';
    final diff = endDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays < 1) return 'Ends in ${diff.inHours}h';
    return 'Ends in ${diff.inDays} days';
  }
}