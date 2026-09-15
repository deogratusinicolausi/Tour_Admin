import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../utils/colors.dart';
import '../widgets/payment_card_widget.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _service = PaymentService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterMethod = 'all';
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _service.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentModel> _filter(List<PaymentModel> all) {
    return all.where((p) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          p.userName.toLowerCase().contains(search) ||
          p.itemName.toLowerCase().contains(search) ||
          p.transactionId.toLowerCase().contains(search);

      final matchStatus =
          _filterStatus == 'all' || p.status == _filterStatus;
      final matchMethod =
          _filterMethod == 'all' || p.method == _filterMethod;

      return matchSearch && matchStatus && matchMethod;
    }).toList();
  }

  Future<void> _approve(PaymentModel payment) async {
    final ok = await _service.approvePayment(payment.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(ok ? '✅ Payment approved!' : '❌ Failed to approve'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      _loadStats();
    }
  }

  Future<void> _refund(PaymentModel payment) async {
    final controller = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('💰 Refund Payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Refund ${payment.currency} ${payment.amount.toStringAsFixed(0)} to ${payment.userName}?'),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Refund Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _service.refundPayment(
        payment.id,
        controller.text.trim().isEmpty
            ? 'Refunded by admin'
            : controller.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '💰 Payment refunded!' : '❌ Failed'),
            backgroundColor: ok ? Colors.orange : Colors.red,
          ),
        );
        _loadStats();
      }
    }
  }

  Future<void> _delete(PaymentModel payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: Text(
            'Delete payment of ${payment.currency} ${payment.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deletePayment(payment.id);
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💰 Payments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // STATS
          _buildStats(width, height),

          // SEARCH
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search payments...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: height * 0.015),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),

          // FILTERS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.008),
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'pending', 'completed', 'failed', 'refunded']
                    .map((status) {
                  final isSelected = _filterStatus == status;
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = status),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.035,
                          vertical: height * 0.006),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        status == 'all' ? '🔔 All' : status.toUpperCase(),
                        style: TextStyle(
                          color:
                          isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.024,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              stream: _service.getAllPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = _filter(snapshot.data ?? []);

                if (payments.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: payments.length,
                  itemBuilder: (context, i) => PaymentCard(
                    payment: payments[i],
                    onApprove: () => _approve(payments[i]),
                    onRefund: () => _refund(payments[i]),
                    onDelete: () => _delete(payments[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      color: AppColors.primary,
      child: Column(
        children: [
          // Main stats
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(width * 0.035),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF4B942),
                        Color(0xFFFFD166),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 TOTAL REVENUE',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '\$${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: width * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: width * 0.02),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_stats['total'] ?? 0}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.055,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.012),
          // Sub stats
          Row(
            children: [
              _subStat('✅', '${_stats['completed'] ?? 0}', 'Completed',
                  Colors.green, width),
              _subStat('⏳', '${_stats['pending'] ?? 0}', 'Pending',
                  Colors.orange, width),
              _subStat('❌', '${_stats['failed'] ?? 0}', 'Failed',
                  Colors.red, width),
              _subStat('💰', '${_stats['refunded'] ?? 0}', 'Refunded',
                  Colors.blue, width),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subStat(String emoji, String value, String label, Color color,
      double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.02, vertical: width * 0.025),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: width * 0.04)),
            SizedBox(height: width * 0.005),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.035,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.022,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined,
              size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text(
            'No payments found',
            style: TextStyle(
              fontSize: width * 0.05,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}