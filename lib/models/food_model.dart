import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  final String id;
  final String name;
  final String category; // Dish, Cuisine, Restaurant, Drink, Dessert, Street Food
  final String subCategory; // Swahili, Maasai, etc.
  final String description;
  final String location;
  final String region;
  final String country;
  final String imageUrl;
  final List<String> gallery;
  final List<String> ingredients;
  final List<String> preparation;
  final String spiceLevel; // Mild, Medium, Hot, Very Hot
  final List<String> dietary; // Vegetarian, Vegan, Halal, Gluten-Free
  final double price;
  final String currency;
  final String servingTime; // Breakfast, Lunch, Dinner, Snack
  final String restaurantName;
  final String contactInfo;
  final List<String> bestPairings; // What goes well with this
  final double rating;
  final bool featured;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FoodModel({
    required this.id,
    required this.name,
    this.category = 'Dish',
    this.subCategory = '',
    required this.description,
    this.location = '',
    this.region = '',
    this.country = 'Tanzania',
    this.imageUrl = '',
    this.gallery = const [],
    this.ingredients = const [],
    this.preparation = const [],
    this.spiceLevel = 'Mild',
    this.dietary = const [],
    this.price = 0.0,
    this.currency = 'USD',
    this.servingTime = 'Lunch',
    this.restaurantName = '',
    this.contactInfo = '',
    this.bestPairings = const [],
    this.rating = 0.0,
    this.featured = false,
    this.status = 'active',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map, String id) {
    return FoodModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Dish',
      subCategory: map['subCategory'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      region: map['region'] ?? '',
      country: map['country'] ?? 'Tanzania',
      imageUrl: map['imageUrl'] ?? '',
      gallery: List<String>.from(map['gallery'] ?? []),
      ingredients: List<String>.from(map['ingredients'] ?? []),
      preparation: List<String>.from(map['preparation'] ?? []),
      spiceLevel: map['spiceLevel'] ?? 'Mild',
      dietary: List<String>.from(map['dietary'] ?? []),
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      servingTime: map['servingTime'] ?? 'Lunch',
      restaurantName: map['restaurantName'] ?? '',
      contactInfo: map['contactInfo'] ?? '',
      bestPairings: List<String>.from(map['bestPairings'] ?? []),
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
      'ingredients': ingredients,
      'preparation': preparation,
      'spiceLevel': spiceLevel,
      'dietary': dietary,
      'price': price,
      'currency': currency,
      'servingTime': servingTime,
      'restaurantName': restaurantName,
      'contactInfo': contactInfo,
      'bestPairings': bestPairings,
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