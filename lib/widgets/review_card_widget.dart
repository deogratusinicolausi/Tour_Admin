import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../utils/colors.dart';

// ⭐️ Star Rating Widget
class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, color: AppColors.accentGold, size: size);
        } else if (i < rating && rating - i >= 0.5) {
          return Icon(Icons.star_half,
              color: AppColors.accentGold, size: size);
        }
        return Icon(Icons.star_border,
            color: AppColors.accentGold, size: size);
      }),
    );
  }
}

// ⭐️ Review Card
class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final VoidCallback onFeature;
  final VoidCallback onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    required this.onTap,
    required this.onReply,
    required this.onFeature,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: review.featured
              ? Border.all(color: AppColors.accentGold, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header strip
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, vertical: height * 0.012),
              decoration: BoxDecoration(
                color: review.featured
                    ? AppColors.accentGold.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.05),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: width * 0.045,
                    backgroundColor: AppColors.primary,
                    backgroundImage: review.userPhoto.isNotEmpty
                        ? NetworkImage(review.userPhoto)
                        : null,
                    child: review.userPhoto.isEmpty
                        ? Text(
                      review.userName.isNotEmpty
                          ? review.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                      ),
                    )
                        : null,
                  ),
                  SizedBox(width: width * 0.025),

                  // Name + Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.035,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (review.verified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        color: Colors.green.shade700,
                                        size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (review.featured) ...[
                              SizedBox(width: width * 0.015),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.star,
                                        size: 10, color: Colors.black),
                                    SizedBox(width: 2),
                                    Text(
                                      'FEATURED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: height * 0.003),
                        Row(
                          children: [
                            StarRating(rating: review.rating, size: 12),
                            SizedBox(width: width * 0.02),
                            Text(
                              review.timeAgo,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: width * 0.024,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${review.itemType.toUpperCase()} • ${review.itemName}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.01),

                  // Title
                  if (review.title.isNotEmpty) ...[
                    Text(
                      review.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                  ],

                  // Comment
                  Text(
                    review.comment,
                    style: TextStyle(
                      fontSize: width * 0.033,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Photos
                  if (review.photos.isNotEmpty) ...[
                    SizedBox(height: height * 0.01),
                    SizedBox(
                      height: height * 0.08,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: review.photos.length,
                        itemBuilder: (context, i) {
                          return Container(
                            margin: EdgeInsets.only(right: width * 0.02),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                review.photos[i],
                                width: height * 0.08,
                                height: height * 0.08,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: height * 0.08,
                                  height: height * 0.08,
                                  color: Colors.grey.shade200,
                                  child:
                                  const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Admin reply
                  if (review.adminReply.isNotEmpty) ...[
                    SizedBox(height: height * 0.012),
                    Container(
                      padding: EdgeInsets.all(width * 0.035),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  color: AppColors.primary,
                                  size: width * 0.035),
                              SizedBox(width: width * 0.015),
                              Text(
                                'TURIVA Reply',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.028,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            review.adminReply,
                            style: TextStyle(
                              fontSize: width * 0.03,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: height * 0.015),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          icon: review.adminReply.isEmpty
                              ? Icons.reply
                              : Icons.edit,
                          label: review.adminReply.isEmpty
                              ? 'Reply'
                              : 'Edit Reply',
                          color: AppColors.primary,
                          onTap: onReply,
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: review.featured
                              ? Icons.star
                              : Icons.star_border,
                          label: review.featured
                              ? 'Unfeature'
                              : 'Feature',
                          color: AppColors.accentGold,
                          onTap: onFeature,
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.delete,
                          label: 'Delete',
                          color: Colors.red,
                          onTap: onDelete,
                          width: width,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: width * 0.025),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: width * 0.04),
            SizedBox(width: width * 0.01),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: width * 0.026,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}