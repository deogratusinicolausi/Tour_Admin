import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';
import '../utils/colors.dart';
import '../widgets/analytics_charts.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _service = PaymentService();

  List<Map<String, dynamic>> _last7Days = [];
  List<Map<String, dynamic>> _last6Months = [];
  Map<String, int> _methods = {};
  List<Map<String, dynamic>> _topItems = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final days = await _service.getRevenueLast7Days();
    final months = await _service.getRevenueLast6Months();
    final methods = await _service.getPaymentMethodsBreakdown();
    final topItems = await _service.getTopSellingItems();
    final stats = await _service.getStats();

    if (mounted) {
      setState(() {
        _last7Days = days;
        _last6Months = months;
        _methods = methods;
        _topItems = topItems;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('📊 ${context.tr('analytics')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATS CARDS
            Row(
              children: [
                _mainStat(
                  '💰',
                  '\$${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                  'Total Revenue',
                  AppColors.accentGold,
                  width,
                ),
                _mainStat(
                  '✅',
                  '${_stats['completed'] ?? 0}',
                  'Completed',
                  Colors.green,
                  width,
                ),
              ],
            ),
            SizedBox(height: height * 0.012),
            Row(
              children: [
                _mainStat(
                  '⏳',
                  '${_stats['pending'] ?? 0}',
                  'Pending',
                  Colors.orange,
                  width,
                ),
                _mainStat(
                  '💰',
                  '\$${(_stats['refundedAmount'] ?? 0).toStringAsFixed(0)}',
                  'Refunded',
                  Colors.blue,
                  width,
                ),
              ],
            ),
            SizedBox(height: height * 0.025),

            // LAST 7 DAYS
            _sectionTitle('📈 Revenue - Last 7 Days', width),
            SizedBox(height: height * 0.015),
            Container(
              height: height * 0.28,
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: RevenueLineChart(data: _last7Days),
            ),
            SizedBox(height: height * 0.025),

            // LAST 6 MONTHS
            _sectionTitle('📊 Revenue - Last 6 Months', width),
            SizedBox(height: height * 0.015),
            Container(
              height: height * 0.3,
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: MonthlyRevenueBarChart(data: _last6Months),
            ),
            SizedBox(height: height * 0.025),

            // PAYMENT METHODS
            _sectionTitle('💳 Payment Methods', width),
            SizedBox(height: height * 0.015),
            Container(
              height: height * 0.25,
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: PaymentMethodsPieChart(data: _methods),
            ),
            SizedBox(height: height * 0.025),

            // TOP SELLING
            _sectionTitle('🏆 Top Selling Items', width),
            SizedBox(height: height * 0.015),
            ..._topItems.take(5).map((item) {
              return Container(
                margin: EdgeInsets.only(bottom: height * 0.01),
                padding: EdgeInsets.all(width * 0.035),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.025),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_fire_department,
                          color: AppColors.accentGold,
                          size: width * 0.05),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item['count']} bookings',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${(item['revenue'] as num).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: height * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _mainStat(String emoji, String value, String label, Color color,
      double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: width * 0.07)),
            SizedBox(height: width * 0.015),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.05,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: width * 0.026,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}