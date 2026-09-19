import 'package:flutter/material.dart';
import '../models/food_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'add_edit_food_screen.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'all';
  String _filterSpice = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'label': 'ALL', 'icon': '🍽️'},
    {'value': 'Dish', 'label': 'DISHES', 'icon': '🍛'},
    {'value': 'Cuisine', 'label': 'CUISINE', 'icon': '🥘'},
    {'value': 'Restaurant', 'label': 'RESTAURANTS', 'icon': '🏨'},
    {'value': 'Drink', 'label': 'DRINKS', 'icon': '🍹'},
    {'value': 'Dessert', 'label': 'DESSERTS', 'icon': '🎂'},
    {'value': 'Street Food', 'label': 'STREET', 'icon': '🍢'},
  ];

  final List<Map<String, String>> _spiceLevels = [
    {'value': 'all', 'label': 'ALL'},
    {'value': 'Mild', 'label': '🟢 MILD'},
    {'value': 'Medium', 'label': '🟡 MEDIUM'},
    {'value': 'Hot', 'label': '🟠 HOT'},
    {'value': 'Very Hot', 'label': '🔴 VERY HOT'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(FoodModel food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('delete_food')),
        content: Text('${context.tr('delete_confirm')} "${food.name}"?'),
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
      final ok = await _service.deleteFood(food.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ ${context.tr('food_deleted')}' : '❌ ${context.tr('failed')}'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openAddEdit([FoodModel? food]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFoodScreen(food: food),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dish':
        return Icons.restaurant;
      case 'Cuisine':
        return Icons.local_dining;
      case 'Restaurant':
        return Icons.store;
      case 'Drink':
        return Icons.local_bar;
      case 'Dessert':
        return Icons.cake;
      case 'Street Food':
        return Icons.fastfood;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Dish':
        return const Color(0xFFff5722);
      case 'Cuisine':
        return const Color(0xFFe91e63);
      case 'Restaurant':
        return const Color(0xFF9c27b0);
      case 'Drink':
        return const Color(0xFF2196f3);
      case 'Dessert':
        return const Color(0xFFff9800);
      case 'Street Food':
        return const Color(0xFF4caf50);
      default:
        return AppColors.primary;
    }
  }

  Color _getSpiceColor(String spice) {
    switch (spice) {
      case 'Mild':
        return Colors.green;
      case 'Medium':
        return Colors.amber;
      case 'Hot':
        return Colors.orange;
      case 'Very Hot':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('🍛 ${context.tr('food_management')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          context.tr('add_food'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                      hintText: context.tr('search_food'),
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
                            context.tr((cat['value'] as String).toLowerCase().replaceAll(' ', '_')).toUpperCase(),
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

          // SPICE FILTER
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.008),
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _spiceLevels.map((spice) {
                  final isSelected = _filterSpice == spice['value'];
                  return GestureDetector(
                    onTap: () => setState(
                            () => _filterSpice = spice['value'] as String),
                    child: Container(
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03,
                          vertical: height * 0.006),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.cardBg
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        spice['value'] == 'all'
                            ? context.tr('all').toUpperCase()
                            : spice['value'] == 'Mild'
                                ? '🟢 ${context.tr('mild').toUpperCase()}'
                                : spice['value'] == 'Medium'
                                    ? '🟡 ${context.tr('medium').toUpperCase()}'
                                    : spice['value'] == 'Hot'
                                        ? '🟠 ${context.tr('hot').toUpperCase()}'
                                        : '🔴 ${context.tr('very_hot').toUpperCase()}',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white70,
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
            child: StreamBuilder<List<FoodModel>>(
              stream: _service.getFood(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final food = all.where((f) {
                  final matchSearch = _searchQuery.isEmpty ||
                      f.name.toLowerCase().contains(_searchQuery) ||
                      f.location.toLowerCase().contains(_searchQuery);
                  final matchCategory = _filterCategory == 'all' ||
                      f.category == _filterCategory;
                  final matchSpice =
                      _filterSpice == 'all' || f.spiceLevel == _filterSpice;
                  return matchSearch && matchCategory && matchSpice;
                }).toList();

                if (food.isEmpty) {
                  return _buildEmptyState(context, width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: food.length,
                  itemBuilder: (context, i) =>
                      _buildFoodCard(context, food[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu,
              size: width * 0.2, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? context.tr('no_food_yet') : context.tr('no_results'),
            style: TextStyle(
              fontSize: width * 0.05,
              color: context.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('tap_to_add_food'),
            style: const TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodModel food, double width, double height) {
    final categoryColor = _getCategoryColor(food.category);
    final categoryIcon = _getCategoryIcon(food.category);
    final spiceColor = _getSpiceColor(food.spiceLevel);

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
                food.imageUrl.isNotEmpty
                    ? Image.network(
                  food.imageUrl,
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
                          context.tr(food.category.toLowerCase().replaceAll(' ', '_')).toUpperCase(),
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
                // Spice level
                if (food.category == 'Dish' ||
                    food.category == 'Street Food')
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: spiceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌶️',
                              style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            context.tr(food.spiceLevel.toLowerCase().replaceAll(' ', '_')).toUpperCase(),
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
                // Featured
                if (food.featured)
                  Positioned(
                    bottom: 10,
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
                          Icon(Icons.star,
                              size: 14, color: Colors.black),
                          SizedBox(width: 4),
                          Text(
                            'FEATURED', // usually untranslated token name or handled by context.tr('featured')
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
                // Featured dynamic translate
                if (food.featured)
                  Positioned(
                    bottom: 10,
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
                          const Icon(Icons.star,
                              size: 14, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('featured').toUpperCase(),
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
                // Price
                if (food.price > 0)
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
                        '${food.currency} ${food.price.toStringAsFixed(0)}',
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
                  food.name,
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: height * 0.005),
                if (food.location.isNotEmpty ||
                    food.restaurantName.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: width * 0.035,
                          color: Colors.grey.shade500),
                      SizedBox(width: width * 0.01),
                      Expanded(
                        child: Text(
                          food.restaurantName.isNotEmpty
                              ? food.restaurantName
                              : '${food.location}, ${food.region}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: width * 0.03,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (food.dietary.isNotEmpty) ...[
                  SizedBox(height: height * 0.008),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: food.dietary.take(3).map((d) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
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
                      child: _actionBtn(
                        icon: Icons.edit,
                        label: context.tr('edit'),
                        color: Colors.blue,
                        onTap: () => _openAddEdit(food),
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: food.featured
                            ? Icons.star
                            : Icons.star_border,
                        label: food.featured ? context.tr('unfeature') : context.tr('feature'),
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _service.toggleFoodFeatured(
                              food.id, !food.featured);
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
                        onTap: () => _delete(food),
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