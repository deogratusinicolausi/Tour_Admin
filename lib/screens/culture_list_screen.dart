import 'package:flutter/material.dart';
import '../models/culture_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'add_edit_culture_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import 'package:provider/provider.dart';

class CultureListScreen extends StatefulWidget {
  const CultureListScreen({super.key});

  @override
  State<CultureListScreen> createState() => _CultureListScreenState();
}

class _CultureListScreenState extends State<CultureListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'all';

  List<Map<String, dynamic>> get _categories => [
    {'value': 'all', 'label': context.tr('all'), 'icon': '🌍'},
    {'value': 'Tribe', 'label': context.tr('tribes'), 'icon': '👥'},
    {'value': 'Festival', 'label': context.tr('festivals'), 'icon': '🎉'},
    {'value': 'Art', 'label': context.tr('arts'), 'icon': '🎨'},
    {'value': 'Music', 'label': context.tr('music'), 'icon': '🎵'},
    {'value': 'Dance', 'label': context.tr('dance'), 'icon': '💃'},
    {'value': 'Food', 'label': context.tr('food'), 'icon': '🍛'},
    {'value': 'Historical', 'label': context.tr('history'), 'icon': '🏛️'},
    {'value': 'Village', 'label': context.tr('villages'), 'icon': '🏠'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(CultureModel culture) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_culture_q')),
        content: Text(
            '${context.tr('confirm_delete')} "${culture.name}"?'),
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
      final ok = await _service.deleteCulture(culture.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ ${context.tr('deleted_success')}' : '❌ ${context.tr('failed')}'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openAddEdit([CultureModel? culture]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCultureScreen(culture: culture),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tribe':
        return Icons.people;
      case 'Festival':
        return Icons.celebration;
      case 'Art':
        return Icons.palette;
      case 'Music':
        return Icons.music_note;
      case 'Dance':
        return Icons.music_video;
      case 'Food':
        return Icons.restaurant;
      case 'Historical':
        return Icons.account_balance;
      case 'Village':
        return Icons.home;
      default:
        return Icons.museum;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tribe':
        return const Color(0xFFe91e63);
      case 'Festival':
        return const Color(0xFFff9800);
      case 'Art':
        return const Color(0xFF9c27b0);
      case 'Music':
        return const Color(0xFF3f51b5);
      case 'Dance':
        return const Color(0xFFf44336);
      case 'Food':
        return const Color(0xFF4caf50);
      case 'Historical':
        return const Color(0xFF795548);
      case 'Village':
        return const Color(0xFF009688);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('🎭 ${context.tr('culture_management')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.accentGold,
        icon: Icon(Icons.add, color: context.cardBg),
        label: Text(
          context.tr('add_culture'),
          style:
          TextStyle(color: context.cardBg, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // SEARCH
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
                      hintText: context.tr('search_culture'),
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
              ],
            ),
          ),

          // CATEGORY CHIPS
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.012),
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _filterCategory == cat['value'];
                  return GestureDetector(
                    onTap: () => setState(
                            () => _filterCategory = cat['value'] as String),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.035,
                          vertical: height * 0.008),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(cat['icon'] as String,
                              style: TextStyle(fontSize: width * 0.035)),
                          SizedBox(width: width * 0.01),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.026,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<CultureModel>>(
              stream: _service.getCulture(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final culture = all.where((c) {
                  final matchSearch = _searchQuery.isEmpty ||
                      c.name.toLowerCase().contains(_searchQuery) ||
                      c.location.toLowerCase().contains(_searchQuery);
                  final matchCategory = _filterCategory == 'all' ||
                      c.category == _filterCategory;
                  return matchSearch && matchCategory;
                }).toList();

                if (culture.isEmpty) {
                  return _buildEmptyState(width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: culture.length,
                  itemBuilder: (context, i) =>
                      _buildCultureCard(culture[i], width, height),
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
          Icon(Icons.category,
              size: width * 0.2, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? context.tr('no_culture_yet') : context.tr('no_results'),
            style: TextStyle(
              fontSize: width * 0.05,
              color: context.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('tap_plus_culture'),
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildCultureCard(
      CultureModel culture, double width, double height) {
    final categoryColor = _getCategoryColor(culture.category);
    final categoryIcon = _getCategoryIcon(culture.category);

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
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                culture.imageUrl.isNotEmpty
                    ? Image.network(
                  culture.imageUrl,
                  height: height * 0.2,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: height * 0.2,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                )
                    : Container(
                  height: height * 0.2,
                  color: Colors.grey.shade200,
                  child: Icon(categoryIcon,
                      size: 40, color: Colors.grey.shade400),
                ),
                // Category badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          culture.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (culture.featured)
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
                      child: const Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'FEATURED',
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
                if (culture.entryFee > 0)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${culture.currency} ${culture.entryFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                  culture.name,
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
                        size: width * 0.035,
                        color: context.textSecondary),
                    SizedBox(width: width * 0.01),
                    Expanded(
                      child: Text(
                        culture.location.isNotEmpty
                            ? '${culture.location}, ${culture.region}'
                            : culture.country,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: width * 0.03,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (culture.languages.isNotEmpty) ...[
                  SizedBox(height: height * 0.005),
                  Row(
                    children: [
                      Icon(Icons.language,
                          size: width * 0.035,
                          color: context.textSecondary),
                      SizedBox(width: width * 0.01),
                      Expanded(
                        child: Text(
                          culture.languages.join(', '),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: width * 0.03,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: height * 0.015),
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: () => _openAddEdit(culture),
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: culture.featured
                            ? Icons.star
                            : Icons.star_border,
                        label: culture.featured
                            ? context.tr('unfeature')
                            : context.tr('feature'),
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _service.toggleCultureFeatured(
                              culture.id, !culture.featured);
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
                        onTap: () => _delete(culture),
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