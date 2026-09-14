import 'package:cloud_firestore/cloud_firestore.dart';

class TourModel {
  final String id;
  final String name;
  final String destinationId;
  final String destinationName;
  final String description;
  final double price;
  final String currency;
  final String duration;
  final List<String> images;
  final List<String> itinerary;
  final List<String> included;
  final List<String> excluded;
  final double rating;
  final bool featured;
  final String status;
  final String tourType;
  final int maxPeople;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TourModel({
    required this.id,
    required this.name,
    required this.destinationId,
    required this.destinationName,
    required this.description,
    required this.price,
    this.currency = 'USD',
    this.duration = '',
    this.images = const [],
    this.itinerary = const [],
    this.included = const [],
    this.excluded = const [],
    this.rating = 0.0,
    this.featured = false,
    this.status = 'active',
    this.tourType = 'Safari',
    this.maxPeople = 10,
    this.createdAt,
    this.updatedAt,
  });

  factory TourModel.fromMap(Map<String, dynamic> map, String id) {
    return TourModel(
      id: id,
      name: map['name'] ?? '',
      destinationId: map['destinationId'] ?? '',
      destinationName: map['destinationName'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      duration: map['duration'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      itinerary: List<String>.from(map['itinerary'] ?? []),
      included: List<String>.from(map['included'] ?? []),
      excluded: List<String>.from(map['excluded'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      featured: map['featured'] ?? false,
      status: map['status'] ?? 'active',
      tourType: map['tourType'] ?? 'Safari',
      maxPeople: map['maxPeople'] ?? 10,
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
      'images': images,
      'itinerary': itinerary,
      'included': included,
      'excluded': excluded,
      'rating': rating,
      'featured': featured,
      'status': status,
      'tourType': tourType,
      'maxPeople': maxPeople,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}