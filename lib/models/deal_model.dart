import 'package:cloud_firestore/cloud_firestore.dart';

class DealModel {
  final String id;
  final String title;
  final String description;
  final int discount;
  final double originalPrice;
  final double salePrice;
  final String currency;
  final String imageUrl;
  final String itemType;
  final String itemId;
  final String itemName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final bool featured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DealModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.originalPrice,
    required this.salePrice,
    this.currency = 'USD',
    this.imageUrl = '',
    this.itemType = 'tour',
    this.itemId = '',
    this.itemName = '',
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.featured = false,
    this.createdAt,
    this.updatedAt,
  });

  factory DealModel.fromMap(Map<String, dynamic> map, String id) {
    return DealModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discount: map['discount'] ?? 0,
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      imageUrl: map['imageUrl'] ?? '',
      itemType: map['itemType'] ?? 'tour',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
      featured: map['featured'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'discount': discount,
      'originalPrice': originalPrice,
      'salePrice': salePrice,
      'currency': currency,
      'imageUrl': imageUrl,
      'itemType': itemType,
      'itemId': itemId,
      'itemName': itemName,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'featured': featured,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}