import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../utils/colors.dart';
import '../widgets/coupon_card_widget.dart';
import 'add_edit_coupon_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final _service = CouponService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterStatus = 'all';
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

  List<CouponModel> _filter(List<CouponModel> all) {
    return all.where((c) {
      final search = _searchQuery.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          c.code.toLowerCase().contains(search) ||
          c.title.toLowerCase().contains(search);

      final matchStatus = _filterStatus == 'all' ||
          (_filterStatus == 'active' && c.isValid) ||
          (_filterStatus == 'inactive' && !c.isValid);

      return matchSearch && matchStatus;
    }).toList();
  }

  Future<void> _delete(CouponModel coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_coupon')),
        content: Text('${context.tr('delete')} "${coupon.code}"? ${context.tr('cannot_be_undone')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteCoupon(coupon.id);
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${context.tr('coupon_deleted')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('🎁 ${context.tr('coupons_promotions')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditCouponScreen()),
          );
          _loadStats();
        },
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          context.tr('create_coupon'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ⭐️ STATS
          _buildStats(width, height),

          // ⭐️ SEARCH
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: context.tr('search_coupons'),
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
                SizedBox(height: height * 0.012),
                Row(
                  children: [
                    _filterChip('all', '🔔 ${context.tr('all')}', width, height),
                    _filterChip('active', '✅ ${context.tr('active')}', width, height),
                    _filterChip('inactive', '⏸️ ${context.tr('inactive')}', width, height),
                  ],
                ),
              ],
            ),
          ),

          // ⭐️ LIST
          Expanded(
            child: StreamBuilder<List<CouponModel>>(
              stream: _service.getAllCoupons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final coupons = _filter(snapshot.data ?? []);

                if (coupons.isEmpty) {
                  return _buildEmptyState(width, height);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: coupons.length,
                  itemBuilder: (context, i) => CouponCard(
                    coupon: coupons[i],
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditCouponScreen(
                              coupon: coupons[i]),
                        ),
                      );
                      _loadStats();
                    },
                    onDelete: () => _delete(coupons[i]),
                    onToggle: () async {
                      await _service.toggleActive(
                          coupons[i].id, !coupons[i].isActive);
                      _loadStats();
                    },
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
      child: Row(
        children: [
          _statBox('🎁', '${_stats['total'] ?? 0}', context.tr('total'), Colors.white,
              width),
          _statBox('✅', '${_stats['active'] ?? 0}', context.tr('active'),
              Colors.green, width),
          _statBox('⏸️', '${_stats['expired'] ?? 0}', context.tr('inactive'),
              Colors.orange, width),
          _statBox('📊', '${_stats['totalUsage'] ?? 0}', context.tr('usage'),
              AppColors.accentGold, width),
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

  Widget _filterChip(
      String value, String label, double width, double height) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.035, vertical: height * 0.008),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.028,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer,
              size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text(
            context.tr('no_coupons_yet'),
            style: TextStyle(
              fontSize: width * 0.05,
              color: context.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            context.tr('create_first_coupon'),
            style: TextStyle(
              fontSize: width * 0.035,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}