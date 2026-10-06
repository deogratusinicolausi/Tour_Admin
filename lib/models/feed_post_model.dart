import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPostModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String imageUrl;       // thumbnail (kwa image ni image yenyewe)
  final String mediaUrl;       // ⭐ URL ya video au image (original)
  final String mediaType;      // ⭐ 'image' au 'video'
  final String caption;
  final String location;
  final int likesCount;
  final int commentsCount;
  final int reportsCount;
  final int savesCount;        // ⭐
  final int sharesCount;       // ⭐
  final int viewsCount;        // ⭐
  final bool isHidden;
  final String hiddenReason;
  final DateTime createdAt;

  FeedPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.location,
    required this.likesCount,
    required this.commentsCount,
    required this.reportsCount,
    required this.savesCount,
    required this.sharesCount,
    required this.viewsCount,
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
      // ⭐ Fallback: kama mediaUrl haipo, tumia imageUrl
      mediaUrl: map['mediaUrl'] ?? map['imageUrl'] ?? '',
      // ⭐ Fallback: kama mediaType haipo, default 'image'
      mediaType: map['mediaType'] ?? 'image',
      caption: map['caption'] ?? '',
      location: map['location'] ?? '',
      likesCount: (map['likesCount'] ?? 0) as int,
      commentsCount: (map['commentsCount'] ?? 0) as int,
      reportsCount: (map['reportsCount'] ?? 0) as int,
      savesCount: (map['savesCount'] ?? 0) as int,
      sharesCount: (map['sharesCount'] ?? 0) as int,
      viewsCount: (map['viewsCount'] ?? 0) as int,
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
      'mediaUrl': mediaUrl,       // ⭐
      'mediaType': mediaType,     // ⭐
      'caption': caption,
      'location': location,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'reportsCount': reportsCount,
      'savesCount': savesCount,   // ⭐
      'sharesCount': sharesCount, // ⭐
      'viewsCount': viewsCount,   // ⭐
      'isHidden': isHidden,
      'hiddenReason': hiddenReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FeedPostModel copyWith({
    bool? isHidden,
    String? hiddenReason,
    int? likesCount,
    int? commentsCount,
    int? savesCount,
    int? sharesCount,
    int? viewsCount,
  }) {
    return FeedPostModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      caption: caption,
      location: location,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      reportsCount: reportsCount,
      savesCount: savesCount ?? this.savesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isHidden: isHidden ?? this.isHidden,
      hiddenReason: hiddenReason ?? this.hiddenReason,
      createdAt: createdAt,
    );
  }

  // ⭐ CONVENIENCE GETTERS
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image' || mediaType.isEmpty;
}