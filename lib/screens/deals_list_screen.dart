import 'package:flutter/material.dart';
import '../models/deal_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'add_edit_deal_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';

class DealsListScreen extends StatefulWidget {
  const DealsListScreen({super.key});

  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen> {
  final _service = FirestoreService();

  Future<void> _delete(DealModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_deal_query')),
        content: Text('${context.tr('delete')} "${d.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _service.deleteDeal(d.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ ${context.tr('deleted')}' : '❌ ${context.tr('failed')}'),
            backgroundColor: ok ? Colors.green : Colors.red,
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
        title: Text('🎁 ${context.tr('special_deals')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditDealScreen()),
          );
        },
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(context.tr('add_deal'),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<DealModel>>(
        stream: _service.getDeals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final deals = snapshot.data ?? [];
          if (deals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard,
                      size: width * 0.2, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(context.tr('no_deals_yet'),
                      style: TextStyle(
                          fontSize: width * 0.05,
                          color: context.textSecondary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(width * 0.04),
            itemCount: deals.length,
            itemBuilder: (context, i) => _card(deals[i], width, height),
          );
        },
      ),
    );
  }

  Widget _card(DealModel d, double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                d.imageUrl.isNotEmpty
                    ? Image.network(d.imageUrl,
                    height: height * 0.18,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: height * 0.18,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 40),
                    ))
                    : Container(
                    height: height * 0.18,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.card_giftcard, size: 40)),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '-${d.discount}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
                if (d.featured)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(context.tr('featured'),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ],
                      ),
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
                Text(
                  d.title,
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: height * 0.005),
                Text(
                  d.itemName,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: width * 0.03),
                ),
                SizedBox(height: height * 0.01),
                Row(
                  children: [
                    Text(
                      '${d.currency} ${d.salePrice.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${d.currency} ${d.originalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: width * 0.032,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: _btn(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditDealScreen(deal: d),
                            ),
                          );
                        },
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _btn(
                        icon: d.featured ? Icons.star : Icons.star_border,
                        label: d.featured ? context.tr('unfeature') : context.tr('feature'),
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _service.toggleDealFeatured(d.id, !d.featured);
                        },
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _btn(
                        icon: Icons.delete,
                        label: context.tr('delete'),
                        color: Colors.red,
                        onTap: () => _delete(d),
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

  Widget _btn({
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
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: width * 0.028,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}