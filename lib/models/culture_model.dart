import 'package:cloud_firestore/cloud_firestore.dart';

class CultureModel {
  final String id;
  final String name;
  final String category; // Tribe, Festival, Art, Music, Dance, Food, Historical, Village
  final String subCategory; // Specific type
  final String description;
  final String location;
  final String region;
  final String country;
  final String imageUrl;
  final List<String> gallery;
  final List<String> highlights;
  final List<String> bestTimeToVisit;
  final String duration;
  final double entryFee;
  final String currency;
  final String contactInfo;
  final List<String> languages;
  final List<String> activities;
  final double rating;
  final bool featured;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CultureModel({
    required this.id,
    required this.name,
    this.category = 'Tribe',
    this.subCategory = '',
    required this.description,
    this.location = '',
    this.region = '',
    this.country = 'Tanzania',
    this.imageUrl = '',
    this.gallery = const [],
    this.highlights = const [],
    this.bestTimeToVisit = const [],
    this.duration = '',
    this.entryFee = 0.0,
    this.currency = 'USD',
    this.contactInfo = '',
    this.languages = const [],
    this.activities = const [],
    this.rating = 0.0,
    this.featured = false,
    this.status = 'active',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory CultureModel.fromMap(Map<String, dynamic> map, String id) {
    return CultureModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Tribe',
      subCategory: map['subCategory'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      region: map['region'] ?? '',
      country: map['country'] ?? 'Tanzania',
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
      highlights: List<String>.from(map['highlights'] ?? []),
      bestTimeToVisit: List<String>.from(map['bestTimeToVisit'] ?? []),
      duration: map['duration'] ?? '',
      entryFee: (map['entryFee'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      contactInfo: map['contactInfo'] ?? '',
      languages: List<String>.from(map['languages'] ?? []),
      activities: List<String>.from(map['activities'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      featured: map['featured'] ?? false,
      status: map['status'] ?? 'active',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'location': location,
      'region': region,
      'country': country,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'highlights': highlights,
      'bestTimeToVisit': bestTimeToVisit,
      'duration': duration,
      'entryFee': entryFee,
      'currency': currency,
      'contactInfo': contactInfo,
      'languages': languages,
      'activities': activities,
      'rating': rating,
      'featured': featured,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}