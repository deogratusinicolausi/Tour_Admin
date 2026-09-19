import 'package:flutter/material.dart';
import '../models/coupon_model.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isValid = coupon.isValid;

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
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
          // ⭐️ Banner with discount
          Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              gradient: isValid
                  ? AppColors.mainGradient
                  : LinearGradient(
                colors: [Colors.white60, Colors.white],
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Discount badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: width * 0.025),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        coupon.discountType == 'percentage'
                            ? '${coupon.discountValue.toStringAsFixed(0)}%'
                            : '\$${coupon.discountValue.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.06,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        context.tr('off'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.03),

                // Title + Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coupon.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isValid ? context.tr('active') : context.tr('inactive'),
                    style: TextStyle(
                      color: context.cardBg,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ⭐️ Details
          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coupon.description.isNotEmpty) ...[
                  Text(
                    coupon.description,
                    style: TextStyle(
                      fontSize: width * 0.032,
                      color: context.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: height * 0.012),
                ],

                // Info grid
                Row(
                  children: [
                    _infoChip(
                      context,
                      Icons.shopping_cart,
                      '${coupon.usedCount}${coupon.usageLimit > 0 ? '/${coupon.usageLimit}' : ''} ${context.tr('used')}',
                      width,
                    ),
                    SizedBox(width: width * 0.02),
                    _infoChip(
                      context,
                      Icons.category,
                      coupon.applicableTo.toUpperCase(),
                      width,
                    ),
                  ],
                ),
                SizedBox(height: height * 0.008),
                Row(
                  children: [
                    if (coupon.minAmount > 0)
                      _infoChip(
                        context,
                        Icons.attach_money,
                        '${context.tr('min')} ${coupon.currency} ${coupon.minAmount.toStringAsFixed(0)}',
                        width,
                      ),
                    if (coupon.endDate != null) ...[
                      SizedBox(width: width * 0.02),
                      _infoChip(
                        context,
                        Icons.calendar_today,
                        coupon.expiryText,
                        width,
                      ),
                    ],
                  ],
                ),

                SizedBox(height: height * 0.015),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: onEdit,
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: coupon.isActive
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        label: coupon.isActive ? context.tr('disable') : context.tr('enable'),
                        color: coupon.isActive
                            ? Colors.orange
                            : Colors.green,
                        onTap: onToggle,
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.delete,
                        label: context.tr('delete'),
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
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text, double width) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.pageBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: width * 0.026,
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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