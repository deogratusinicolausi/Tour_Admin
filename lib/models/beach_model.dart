import 'package:cloud_firestore/cloud_firestore.dart';

class BeachModel {
  final String id;
  final String name;
  final String destinationId;
  final String destinationName;
  final String description;
  final String location;
  final String country;
  final String imageUrl;
  final List<String> gallery;
  final List<String> activities;
  final String bestTime;
  final String waterType;
  final double rating;
  final bool featured;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BeachModel({
    required this.id,
    required this.name,
    this.destinationId = '',
    this.destinationName = '',
    required this.description,
    this.location = '',
    this.country = 'Tanzania',
    this.imageUrl = '',
    this.gallery = const [],
    this.activities = const [],
    this.bestTime = 'All Year',
    this.waterType = 'Ocean',
    this.rating = 0.0,
    this.featured = false,
    this.status = 'active',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory BeachModel.fromMap(Map<String, dynamic> map, String id) {
    return BeachModel(
      id: id,
      name: map['name'] ?? '',
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      country: map['country'] ?? 'Tanzania',
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
      activities: List<String>.from(map['activities'] ?? []),
      bestTime: map['bestTime'] ?? 'All Year',
      waterType: map['waterType'] ?? 'Ocean',
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
      'destinationId': destinationId,
      'destinationName': destinationName,
      'description': description,
      'location': location,
      'country': country,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'activities': activities,
      'bestTime': bestTime,
      'waterType': waterType,
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