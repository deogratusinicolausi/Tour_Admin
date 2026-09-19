import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cancellation_model.dart';
import '../services/cancellation_service.dart';
import '../utils/colors.dart';

class AdminCancellationsScreen extends StatefulWidget {
  const AdminCancellationsScreen({super.key});

  @override
  State<AdminCancellationsScreen> createState() =>
      _AdminCancellationsScreenState();
}

class _AdminCancellationsScreenState
    extends State<AdminCancellationsScreen> {
  final _service = CancellationService();
  String _filter = 'all';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _service.getGlobalStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('❌ Cancellations & Refunds'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // STATS
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Row(
              children: [
                _statBox('⏳', '${_stats['pending'] ?? 0}', 'Pending',
                    Colors.orange, width),
                _statBox('✅', '${_stats['approved'] ?? 0}', 'Approved',
                    Colors.green, width),
                _statBox('❌', '${_stats['rejected'] ?? 0}', 'Rejected',
                    Colors.red, width),
                _statBox('💰', '${_stats['refunded'] ?? 0}', 'Refunded',
                    Colors.blue, width),
              ],
            ),
          ),

          // FILTERS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'pending', 'approved', 'rejected', 'refunded']
                    .map((f) {
                  final isSelected = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: height * 0.008),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f.toUpperCase(),
                        style: TextStyle(
                          color:
                          isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.028,
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
            child: StreamBuilder<List<CancellationModel>>(
              stream: _service.getAllCancellations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var cancellations = snapshot.data ?? [];
                if (_filter != 'all') {
                  cancellations = cancellations
                      .where((c) => c.status == _filter)
                      .toList();
                }

                if (cancellations.isEmpty) {
                  return _buildEmpty(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: cancellations.length,
                  itemBuilder: (context, i) => _buildCard(
                      cancellations[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String emoji, String value, String label, Color color,
      double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.02, vertical: width * 0.025),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: width * 0.05)),
            SizedBox(height: width * 0.005),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.04,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.022,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(CancellationModel c, double width, double height) {
    Color statusColor;
    switch (c.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

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
          // Status Strip
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.012),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  c.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.032,
                  ),
                ),
                const Spacer(),
                Text(
                  c.timeAgo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: width * 0.026,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User + Item
                Row(
                  children: [
                    if (c.itemImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          c.itemImage,
                          width: width * 0.15,
                          height: width * 0.15,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: width * 0.15,
                            height: width * 0.15,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.itemName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            'by ${c.userName}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: width * 0.03,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.015),

                // Amounts
                Row(
                  children: [
                    Expanded(
                      child: _amountBox(
                        'Original',
                        '${c.currency} ${c.bookingAmount.toStringAsFixed(0)}',
                        Colors.grey,
                        width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _amountBox(
                        'Refund (${c.refundPercentage}%)',
                        '${c.currency} ${c.refundAmount.toStringAsFixed(0)}',
                        Colors.green,
                        width,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.015),

                // Reason
                Container(
                  padding: EdgeInsets.all(width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.03,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        c.reasonText,
                        style: TextStyle(
                          fontSize: width * 0.032,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (c.additionalNotes.isNotEmpty) ...[
                        SizedBox(height: height * 0.005),
                        Text(
                          c.additionalNotes,
                          style: TextStyle(
                            fontSize: width * 0.028,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                if (c.status == 'pending') ...[
                  SizedBox(height: height * 0.015),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.check,
                          label: 'Approve',
                          color: Colors.green,
                          onTap: () => _approve(c),
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.close,
                          label: 'Reject',
                          color: Colors.red,
                          onTap: () => _reject(c),
                          width: width,
                        ),
                      ),
                    ],
                  ),
                ],

                if (c.status == 'approved') ...[
                  SizedBox(height: height * 0.015),
                  SizedBox(
                    width: double.infinity,
                    child: _actionBtn(
                      icon: Icons.attach_money,
                      label: 'Process Refund',
                      color: Colors.blue,
                      onTap: () => _processRefund(c),
                      width: width,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountBox(
      String label, String value, Color color, double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: width * 0.026,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.005),
          Text(
            value,
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
              color: color,
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
        padding: EdgeInsets.symmetric(vertical: width * 0.03),
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
                fontSize: width * 0.03,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text(
            'No cancellations',
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

  Future<void> _approve(CancellationModel c) async {
    final notes = await _getNotes('Approve Cancellation?',
        'Add notes (optional)');
    if (notes == null) return;
    await _service.approveCancellation(c.id, notes);
    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cancellation approved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _reject(CancellationModel c) async {
    final reason = await _getNotes('Reject Cancellation?',
        'Reason for rejection (required)');
    if (reason == null || reason.isEmpty) return;
    await _service.rejectCancellation(c.id, reason);
    _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Cancellation rejected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processRefund(CancellationModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Process Refund?'),
        content: Text(
            'Refund ${c.currency} ${c.refundAmount.toStringAsFixed(0)} to ${c.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.processRefund(c.id);
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💰 Refund processed!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  Future<String?> _getNotes(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child:
            const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}