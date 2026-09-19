import 'package:flutter/material.dart';
import '../models/beach_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';
import 'add_edit_beach_screen.dart';

class BeachesListScreen extends StatefulWidget {
  const BeachesListScreen({super.key});

  @override
  State<BeachesListScreen> createState() => _BeachesListScreenState();
}

class _BeachesListScreenState extends State<BeachesListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(BeachModel beach) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_beach_q')),
        content: Text('${context.tr('delete_confirm')} "${beach.name}"?'),
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
      final ok = await _service.deleteBeach(beach.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ ${context.tr('deleted_success')}' : '❌ ${context.tr('failed')}'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openAddEdit([BeachModel? beach]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditBeachScreen(beach: beach),
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
        title: Text('🏖️ ${context.tr('beaches')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          context.tr('add_beach'),
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
                      hintText: context.tr('search_beaches'),
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
                            vertical: height * 0.008),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentGold
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr(status).toUpperCase(),
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
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<BeachModel>>(
              stream: _service.getBeaches(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final beaches = all.where((b) {
                  final matchSearch = _searchQuery.isEmpty ||
                      b.name.toLowerCase().contains(_searchQuery) ||
                      b.location.toLowerCase().contains(_searchQuery);
                  final matchStatus =
                      _filterStatus == 'all' || b.status == _filterStatus;
                  return matchSearch && matchStatus;
                }).toList();

                if (beaches.isEmpty) {
                  return _buildEmptyState(width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: beaches.length,
                  itemBuilder: (context, i) =>
                      _buildBeachCard(beaches[i], width, height),
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
          Icon(Icons.beach_access,
              size: width * 0.2, color: context.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? context.tr('no_beaches') : context.tr('no_results'),
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

  Widget _buildBeachCard(BeachModel beach, double width, double height) {
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                beach.imageUrl.isNotEmpty
                    ? Image.network(
                  beach.imageUrl,
                  height: height * 0.18,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: height * 0.18,
                    color: context.textSecondary.withOpacity(0.1),
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                )
                    : Container(
                  height: height * 0.18,
                  color: context.textSecondary.withOpacity(0.1),
                  child: const Icon(Icons.beach_access, size: 40),
                ),
                if (beach.featured)
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
                      color: beach.status == 'active'
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.tr(beach.status).toUpperCase(),
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
          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beach.name,
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
                        beach.location.isNotEmpty
                            ? beach.location
                            : beach.destinationName,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: width * 0.03,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: () => _openAddEdit(beach),
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: beach.featured
                            ? Icons.star
                            : Icons.star_border,
                        label: beach.featured ? context.tr('unfeature') : context.tr('feature'),
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _service.toggleBeachFeatured(
                              beach.id, !beach.featured);
                        },
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.delete,
                        label: context.tr('delete'),
                        color: Colors.red,
                        onTap: () => _delete(beach),
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