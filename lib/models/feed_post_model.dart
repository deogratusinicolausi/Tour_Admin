import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final String caption;
  final String location;
  final int likesCount;
  final int commentsCount;
  final int reportsCount;      // ⭐ NEW — admin moderation
  final bool isHidden;         // ⭐ NEW — admin moderation
  final String hiddenReason;   // ⭐ NEW
  final DateTime createdAt;

  FeedPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.caption,
    required this.location,
    required this.likesCount,
    required this.commentsCount,
    required this.reportsCount,
    required this.isHidden,
    required this.hiddenReason,
    required this.createdAt,
  });

  factory FeedPostModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedPostModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Traveler',
      userAvatar: map['userAvatar'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      location: map['location'] ?? '',
      likesCount: (map['likesCount'] ?? 0) as int,
      commentsCount: (map['commentsCount'] ?? 0) as int,
      reportsCount: (map['reportsCount'] ?? 0) as int,
      isHidden: map['isHidden'] ?? false,
      hiddenReason: map['hiddenReason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'reportsCount': reportsCount,
      'isHidden': isHidden,
      'hiddenReason': hiddenReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FeedPostModel copyWith({
    bool? isHidden,
    String? hiddenReason,
  }) {
    return FeedPostModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      imageUrl: imageUrl,
      caption: caption,
      location: location,
      likesCount: likesCount,
      commentsCount: commentsCount,
      reportsCount: reportsCount,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      createdAt: createdAt,
    );
  }
}