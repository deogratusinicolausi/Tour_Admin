import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../utils/colors.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback onApprove;
  final VoidCallback onRefund;
  final VoidCallback onDelete;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onApprove,
    required this.onRefund,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (payment.status) {
      case 'completed':
        return Colors.green;
      case 'refunded':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (payment.status) {
      case 'completed':
        return Icons.check_circle;
      case 'refunded':
        return Icons.replay;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  IconData get _methodIcon {
    switch (payment.method) {
      case 'mpesa':
      case 'tigopesa':
      case 'airtel':
        return Icons.phone_android;
      case 'bank':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Status strip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.012,
            ),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon,
                    color: _statusColor, size: width * 0.045),
                SizedBox(width: width * 0.02),
                Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.03,
                  ),
                ),
                const Spacer(),
                Icon(_methodIcon,
                    color: Colors.grey.shade600, size: width * 0.04),
                SizedBox(width: width * 0.01),
                Text(
                  payment.method.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: width * 0.028,
                    fontWeight: FontWeight.w600,
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
                // Amount + Date
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            payment.itemName.isNotEmpty
                                ? payment.itemName
                                : 'Payment',
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      payment.timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: width * 0.028,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.012),

                // User info
                Row(
                  children: [
                    Icon(Icons.person,
                        size: width * 0.035, color: Colors.grey.shade500),
                    SizedBox(width: width * 0.01),
                    Text(
                      payment.userName,
                      style: TextStyle(
                        fontSize: width * 0.03,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (payment.userPhone.isNotEmpty) ...[
                      SizedBox(width: width * 0.03),
                      Icon(Icons.phone,
                          size: width * 0.035,
                          color: Colors.grey.shade500),
                      SizedBox(width: width * 0.01),
                      Text(
                        payment.userPhone,
                        style: TextStyle(
                          fontSize: width * 0.028,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: height * 0.015),

                // Action buttons
                Row(
                  children: [
                    if (payment.status == 'pending') ...[
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.check,
                          label: 'Approve',
                          color: Colors.green,
                          onTap: onApprove,
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                    ],
                    if (payment.status == 'completed') ...[
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.replay,
                          label: 'Refund',
                          color: Colors.orange,
                          onTap: onRefund,
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                    ],
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
                fontSize: width * 0.028,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}