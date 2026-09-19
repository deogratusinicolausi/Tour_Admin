import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import 'package:provider/provider.dart';
import 'add_edit_destination_screen.dart';

class DestinationsListScreen extends StatefulWidget {
  const DestinationsListScreen({super.key});

  @override
  State<DestinationsListScreen> createState() => _DestinationsListScreenState();
}

class _DestinationsListScreenState extends State<DestinationsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteDestination(DestinationModel dest) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_destination_q')),
        content: Text('${context.tr('confirm_delete')} "${dest.name}"?'),
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
      final success = await _firestoreService.deleteDestination(dest.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '✅ ${context.tr('deleted_success')}'
                : '❌ ${context.tr('delete_failed')}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openAddEdit([DestinationModel? destination]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditDestinationScreen(destination: destination),
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
        title: Text('📍 ${context.tr('destinations')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          context.tr('add_destination'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ===== SEARCH + FILTER =====
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Column(
              children: [
                // Search
                Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: context.tr('search_destinations'),
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

                // Filter chips
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
                          status.toUpperCase(),
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

          // ===== LIST =====
          Expanded(
            child: StreamBuilder<List<DestinationModel>>(
              stream: _firestoreService.getDestinations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final allDestinations = snapshot.data ?? [];
                final destinations = allDestinations.where((dest) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      dest.name.toLowerCase().contains(_searchQuery) ||
                      dest.country.toLowerCase().contains(_searchQuery) ||
                      dest.location.toLowerCase().contains(_searchQuery);

                  final matchesStatus = _filterStatus == 'all' ||
                      dest.status == _filterStatus;

                  return matchesSearch && matchesStatus;
                }).toList();

                if (destinations.isEmpty) {
                  return _buildEmptyState(width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    return _buildDestinationCard(
                      destinations[index],
                      width,
                      height,
                    );
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
          Icon(Icons.location_off, size: width * 0.2, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? context.tr('no_destinations')
                : context.tr('no_results'),
            style: TextStyle(
              fontSize: width * 0.05,
              color: context.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _searchQuery.isEmpty
                ? context.tr('tap_to_add')
                : context.tr('try_different_search'),
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(
      DestinationModel dest,
      double width,
      double height,
      ) {
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                dest.imageUrl.isNotEmpty
                    ? Image.network(
                  dest.imageUrl,
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
                  child: const Icon(Icons.image, size: 40),
                ),
                // Featured badge
                if (dest.featured)
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
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'FEATURED', // Internal tag, usually not translated
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Status badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: dest.status == 'active'
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dest.status.toUpperCase(),
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
                  dest.name,
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
                        size: width * 0.035, color: Colors.grey.shade500),
                    SizedBox(width: width * 0.01),
                    Expanded(
                      child: Text(
                        '${dest.location}, ${dest.country}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: width * 0.03,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (dest.description.isNotEmpty) ...[
                  SizedBox(height: height * 0.005),
                  Text(
                    dest.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: width * 0.03,
                    ),
                  ),
                ],
                SizedBox(height: height * 0.015),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: () => _openAddEdit(dest),
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _buildActionButton(
                        icon: dest.featured ? Icons.star : Icons.star_border,
                        label: dest.featured ? context.tr('unfeature') : context.tr('feature'),
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _firestoreService.toggleFeatured(
                              dest.id, !dest.featured);
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
                        onTap: () => _deleteDestination(dest),
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