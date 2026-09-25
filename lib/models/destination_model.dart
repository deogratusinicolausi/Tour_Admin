import 'package:cloud_firestore/cloud_firestore.dart';

class DestinationModel {
  final String id;
  final String name;
  final String country;
  final String region;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final List<String> gallery;
  final List<String> videos;        // ⭐ ONGEZA HII
  final String videoUrl;
  final double rating;
  final bool featured;
  final String status; // active, inactive
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DestinationModel({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.description,
    required this.location,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.gallery = const [],
    this.videos = const [],           // ⭐ ONGEZA
    this.videoUrl = '',
    this.rating = 0.0,
    this.featured = false,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  // ⭐️ From Firestore
  factory DestinationModel.fromMap(Map<String, dynamic> map, String id) {
    return DestinationModel(
      id: id,
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      region: map['region'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
        videos: List<String>.from(map['videos'] ?? []),        // ⭐ ONGEZA
        videoUrl: map['videoUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      featured: map['featured'] ?? false,
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // ⭐️ To Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'region': region,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'videos': videos,                  // ⭐ ONGEZA
      'videoUrl': videoUrl,
      'rating': rating,
      'featured': featured,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DestinationModel copyWith({
    String? name,
    String? country,
    String? region,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? gallery,
    double? rating,
    bool? featured,
    String? status,
  }) {
    return DestinationModel(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      region: region ?? this.region,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      gallery: gallery ?? this.gallery,
      rating: rating ?? this.rating,
      featured: featured ?? this.featured,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}