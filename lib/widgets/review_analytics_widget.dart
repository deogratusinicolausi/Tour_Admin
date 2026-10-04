import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';   // ⬅️ ONGEZA

class ReviewAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ReviewAnalyticsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Rating Breakdown',
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: height * 0.02),
          ..._buildRatingBars(width, context),
        ],
      ),
    );
  }

  List<Widget> _buildRatingBars(double width, BuildContext context) {
    return [5, 4, 3, 2, 1].map((star) {
      final count = (stats['$star'] ?? 0) as num;
      final total = (stats['total'] ?? 1) as num;
      final percent = total > 0 ? (count / total) : 0.0;

      return Padding(
        padding: EdgeInsets.symmetric(vertical: width * 0.01),
        child: Row(
          children: [
            SizedBox(
              width: width * 0.15,
              child: Row(
                children: [
                  Text(
                    '$star',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.035,
                      color: context.textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.star,
                    color: AppColors.accentGold,
                    size: width * 0.035,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: context.chipBg,
                  color: AppColors.accentGold,
                  minHeight: 8,
                ),
              ),
            ),
            SizedBox(width: width * 0.03),
            SizedBox(
              width: width * 0.1,
              child: Text(
                '$count',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.03,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}