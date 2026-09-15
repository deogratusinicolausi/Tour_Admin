import 'package:cloud_firestore/cloud_firestore.dart';

class MountainModel {
  final String id;
  final String name;
  final String destinationId;
  final String destinationName;
  final String description;
  final String location;
  final String country;
  final String imageUrl;
  final List<String> gallery;
  final double height; // meters
  final String difficulty; // Easy, Moderate, Hard, Extreme
  final String duration; // e.g., "5-7 days"
  final String bestTime; // e.g., "June-October"
  final List<String> routes; // e.g., ["Marangu", "Machame"]
  final List<String> included;
  final List<String> excluded;
  final List<String> highlights;
  final double rating;
  final bool featured;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MountainModel({
    required this.id,
    required this.name,
    this.destinationId = '',
    this.destinationName = '',
    required this.description,
    this.location = '',
    this.country = 'Tanzania',
    this.imageUrl = '',
    this.gallery = const [],
    this.height = 0.0,
    this.difficulty = 'Moderate',
    this.duration = '',
    this.bestTime = 'All Year',
    this.routes = const [],
    this.included = const [],
    this.excluded = const [],
    this.highlights = const [],
    this.rating = 0.0,
    this.featured = false,
    this.status = 'active',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory MountainModel.fromMap(Map<String, dynamic> map, String id) {
    return MountainModel(
      id: id,
      name: map['name'] ?? '',
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      country: map['country'] ?? 'Tanzania',
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
      height: (map['height'] ?? 0.0).toDouble(),
      difficulty: map['difficulty'] ?? 'Moderate',
      duration: map['duration'] ?? '',
      bestTime: map['bestTime'] ?? 'All Year',
      routes: List<String>.from(map['routes'] ?? []),
      included: List<String>.from(map['included'] ?? []),
      excluded: List<String>.from(map['excluded'] ?? []),
      highlights: List<String>.from(map['highlights'] ?? []),
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
      'height': height,
      'difficulty': difficulty,
      'duration': duration,
      'bestTime': bestTime,
      'routes': routes,
      'included': included,
      'excluded': excluded,
      'highlights': highlights,
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