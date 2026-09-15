import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // customer, admin, superAdmin
  final String status; // active, banned, suspended
  final String photoUrl;
  final String country;
  final String city;
  final String bio;
  final int totalBookings;
  final double totalSpent;
  final int totalReviews;
  final int totalWishlists;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'customer',
    this.status = 'active',
    this.photoUrl = '',
    this.country = '',
    this.city = '',
    this.bio = '',
    this.totalBookings = 0,
    this.totalSpent = 0.0,
    this.totalReviews = 0,
    this.totalWishlists = 0,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'customer',
      status: map['status'] ?? 'active',
      photoUrl: map['photoUrl'] ?? '',
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      bio: map['bio'] ?? '',
      totalBookings: map['totalBookings'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      totalWishlists: map['totalWishlists'] ?? 0,
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'photoUrl': photoUrl,
      'country': country,
      'city': city,
      'bio': bio,
      'totalBookings': totalBookings,
      'totalSpent': totalSpent,
      'totalReviews': totalReviews,
      'totalWishlists': totalWishlists,
      'lastLogin':
      lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get timeAgo {
    if (createdAt == null) return 'unknown';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  String get lastLoginAgo {
    if (lastLogin == null) return 'Never';
    final diff = DateTime.now().difference(lastLogin!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }
}