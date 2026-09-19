import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import 'package:provider/provider.dart';
import 'add_edit_hotel_screen.dart';

class HotelsListScreen extends StatefulWidget {
  const HotelsListScreen({super.key});

  @override
  State<HotelsListScreen> createState() => _HotelsListScreenState();
}

class _HotelsListScreenState extends State<HotelsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteHotel(HotelModel hotel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_hotel_q')),
        content: Text('${context.tr('confirm_delete')} "${hotel.name}"?'),
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
      final success = await _firestoreService.deleteHotel(hotel.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '✅ ${context.tr('hotel_deleted')}'
                : '❌ ${context.tr('failed_delete')}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openAddEdit([HotelModel? hotel]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditHotelScreen(hotel: hotel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('🏨 ${context.tr('hotels')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          context.tr('add_hotel'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // SEARCH + FILTER
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
                      hintText: context.tr('search_hotels'),
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
                SizedBox(height: height * 0.015),
                Row(
                  children: ['all', 'active', 'inactive'].map((status) {
                    final isSelected = _filterStatus == status;
                    return GestureDetector(
                      onTap: () => setState(() => _filterStatus = status),
                      child: Container(
                        margin: EdgeInsets.only(right: width * 0.02),
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: height * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentGold
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr(status).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.028,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<HotelModel>>(
              stream: _firestoreService.getHotels(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allHotels = snapshot.data ?? [];
                final hotels = allHotels.where((h) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      h.name.toLowerCase().contains(_searchQuery) ||
                      h.location.toLowerCase().contains(_searchQuery);
                  final matchesStatus =
                      _filterStatus == 'all' || h.status == _filterStatus;
                  return matchesSearch && matchesStatus;
                }).toList();

                if (hotels.isEmpty) {
                  return _buildEmptyState(width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: hotels.length,
                  itemBuilder: (context, index) {
                    return _buildHotelCard(hotels[index], width, height);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel, size: width * 0.2, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? context.tr('no_hotels') : context.tr('no_results'),
            style: TextStyle(
              fontSize: width * 0.05,
              color: context.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(HotelModel hotel, double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: context.cardBg,
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
          // Image
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                hotel.imageUrl.isNotEmpty
                    ? Image.network(
                  hotel.imageUrl,
                  height: height * 0.18,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: height * 0.18,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                )
                    : Container(
                  height: height * 0.18,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.hotel, size: 40),
                ),
                // Price badge
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${hotel.currency} ${hotel.priceFrom.toStringAsFixed(0)}+',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (hotel.featured)
                  Positioned(
                    top: 10,
                    left: 10,
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
                          Text(
                            context.tr('featured').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hotel.status == 'active'
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.tr(hotel.status).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.name,
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: height * 0.005),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: width * 0.035, color: context.textSecondary),
                    SizedBox(width: width * 0.01),
                    Expanded(
                      child: Text(
                        hotel.location.isNotEmpty
                            ? hotel.location
                            : hotel.destinationName,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: width * 0.03,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (hotel.facilities.isNotEmpty) ...[
                  SizedBox(height: height * 0.01),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hotel.facilities.take(4).map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: () => _openAddEdit(hotel),
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _buildActionButton(
                        icon: hotel.featured ? Icons.star : Icons.star_border,
                        label: hotel.featured
                            ? context.tr('unfeature')
                            : context.tr('feature'),
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _firestoreService.toggleHotelFeatured(
                              hotel.id, !hotel.featured);
                        },
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: context.tr('delete'),
                        color: Colors.red,
                        onTap: () => _deleteHotel(hotel),
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

  Widget _buildActionButton({
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