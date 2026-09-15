import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // customer, admin, superAdmin
  final String photoUrl;
  final String status; // active, banned, suspended
  final String phone;
  final String country;
  final int totalBookings;
  final double totalSpent;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'customer',
    this.photoUrl = '',
    this.status = 'active',
    this.phone = '',
    this.country = '',
    this.totalBookings = 0,
    this.totalSpent = 0.0,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? 'active',
      phone: map['phone'] ?? '',
      country: map['country'] ?? '',
      totalBookings: map['totalBookings'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'status': status,
      'phone': phone,
      'country': country,
      'totalBookings': totalBookings,
      'totalSpent': totalSpent,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
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