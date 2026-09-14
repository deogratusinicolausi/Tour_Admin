import 'package:cloud_firestore/cloud_firestore.dart';

class HotelModel {
  final String id;
  final String name;
  final String destinationId;
  final String destinationName;
  final String description;
  final double priceFrom;
  final String currency;
  final List<String> facilities;
  final String imageUrl;
  final List<String> gallery;
  final double rating;
  final String location;
  final String status;
  final bool featured;
  final String contactPhone;
  final String contactEmail;
  final String website;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HotelModel({
    required this.id,
    required this.name,
    required this.destinationId,
    required this.destinationName,
    required this.description,
    required this.priceFrom,
    this.currency = 'USD',
    this.facilities = const [],
    this.imageUrl = '',
    this.gallery = const [],
    this.rating = 0.0,
    this.location = '',
    this.status = 'active',
    this.featured = false,
    this.contactPhone = '',
    this.contactEmail = '',
    this.website = '',
    this.createdAt,
    this.updatedAt,
  });

  factory HotelModel.fromMap(Map<String, dynamic> map, String id) {
    return HotelModel(
      id: id,
      name: map['name'] ?? '',
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      description: map['description'] ?? '',
      priceFrom: (map['priceFrom'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      facilities: List<String>.from(map['facilities'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      location: map['location'] ?? '',
      status: map['status'] ?? 'active',
      featured: map['featured'] ?? false,
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      website: map['website'] ?? '',
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
      'priceFrom': priceFrom,
      'currency': currency,
      'facilities': facilities,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'rating': rating,
      'location': location,
      'status': status,
      'featured': featured,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'website': website,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}