import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String name;
  final String destinationId;
  final String destinationName;
  final String description;
  final double price;
  final String currency;
  final String duration;
  final String imageUrl;
  final List<String> gallery;
  final double rating;
  final String status;
  final bool featured;
  final String activityType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ActivityModel({
    required this.id,
    required this.name,
    required this.destinationId,
    required this.destinationName,
    required this.description,
    required this.price,
    this.currency = 'USD',
    this.duration = '',
    this.imageUrl = '',
    this.gallery = const [],
    this.rating = 0.0,
    this.status = 'active',
    this.featured = false,
    this.activityType = 'Adventure',
    this.createdAt,
    this.updatedAt,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      name: map['name'] ?? '',
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      duration: map['duration'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'active',
      featured: map['featured'] ?? false,
      activityType: map['activityType'] ?? 'Adventure',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'description': description,
      'price': price,
      'currency': currency,
      'duration': duration,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'rating': rating,
      'status': status,
      'featured': featured,
      'activityType': activityType,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}