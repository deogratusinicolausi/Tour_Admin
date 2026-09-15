import 'package:flutter/material.dart';
import '../models/mountain_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'add_edit_mountain_screen.dart';

class MountainsListScreen extends StatefulWidget {
  const MountainsListScreen({super.key});

  @override
  State<MountainsListScreen> createState() => _MountainsListScreenState();
}

class _MountainsListScreenState extends State<MountainsListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterDifficulty = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(MountainModel mountain) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Mountain?'),
        content: Text(
            'Are you sure you want to delete "${mountain.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _service.deleteMountain(mountain.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ Mountain deleted' : '❌ Failed'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openAddEdit([MountainModel? mountain]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditMountainScreen(mountain: mountain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🏔️ Mountains Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        backgroundColor: AppColors.accentGold,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Add Mountain',
          style:
          TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search mountains...',
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
                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all', 'ALL', _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                      }, width, height),
                      _filterChip('active', 'ACTIVE', _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                      }, width, height),
                      _filterChip('inactive', 'INACTIVE', _filterStatus, (v) {
                        setState(() => _filterStatus = v);
                      }, width, height),
                    ],
                  ),
                ),
                SizedBox(height: height * 0.01),
                // Difficulty filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _difficultyChip(
                          'all', 'ALL LEVELS', _filterDifficulty, (v) {
                        setState(() => _filterDifficulty = v);
                      }, width, height),
                      _difficultyChip('Easy', '🟢 EASY', _filterDifficulty, (v) {
                        setState(() => _filterDifficulty = v);
                      }, width, height),
                      _difficultyChip('Moderate', '🟡 MODERATE',
                          _filterDifficulty, (v) {
                            setState(() => _filterDifficulty = v);
                          }, width, height),
                      _difficultyChip('Hard', '🟠 HARD', _filterDifficulty, (v) {
                        setState(() => _filterDifficulty = v);
                      }, width, height),
                      _difficultyChip('Extreme', '🔴 EXTREME',
                          _filterDifficulty, (v) {
                            setState(() => _filterDifficulty = v);
                          }, width, height),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<MountainModel>>(
              stream: _service.getMountains(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final mountains = all.where((m) {
                  final matchSearch = _searchQuery.isEmpty ||
                      m.name.toLowerCase().contains(_searchQuery) ||
                      m.location.toLowerCase().contains(_searchQuery);
                  final matchStatus =
                      _filterStatus == 'all' || m.status == _filterStatus;
                  final matchDifficulty = _filterDifficulty == 'all' ||
                      m.difficulty == _filterDifficulty;
                  return matchSearch && matchStatus && matchDifficulty;
                }).toList();

                if (mountains.isEmpty) {
                  return _buildEmptyState(width);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: mountains.length,
                  itemBuilder: (context, i) =>
                      _buildMountainCard(mountains[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      String value,
      String label,
      String currentValue,
      Function(String) onChanged,
      double width,
      double height,
      ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.04, vertical: height * 0.008),
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

  Widget _difficultyChip(
      String value,
      String label,
      String currentValue,
      Function(String) onChanged,
      double width,
      double height,
      ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: EdgeInsets.only(right: width * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.035, vertical: height * 0.006),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: width * 0.024,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terrain,
              size: width * 0.2, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'No mountains yet' : 'No results',
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

  Widget _buildMountainCard(
      MountainModel mountain, double width, double height) {
    Color difficultyColor;
    switch (mountain.difficulty) {
      case 'Easy':
        difficultyColor = Colors.green;
        break;
      case 'Hard':
        difficultyColor = Colors.orange;
        break;
      case 'Extreme':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.amber;
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
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                mountain.imageUrl.isNotEmpty
                    ? Image.network(
                  mountain.imageUrl,
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
                  child: const Icon(Icons.terrain, size: 40),
                ),
                // Height badge
                if (mountain.height > 0)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.height,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${mountain.height.toStringAsFixed(0)} m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Featured
                if (mountain.featured)
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
                // Difficulty badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: difficultyColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mountain.difficulty.toUpperCase(),
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
                  mountain.name,
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: height * 0.005),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: width * 0.035,
                        color: Colors.grey.shade500),
                    SizedBox(width: width * 0.01),
                    Expanded(
                      child: Text(
                        mountain.location.isNotEmpty
                            ? mountain.location
                            : mountain.country,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: width * 0.03,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (mountain.duration.isNotEmpty) ...[
                  SizedBox(height: height * 0.005),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: width * 0.035,
                          color: Colors.grey.shade500),
                      SizedBox(width: width * 0.01),
                      Text(
                        mountain.duration,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: width * 0.03,
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
                        label: 'Edit',
                        color: Colors.blue,
                        onTap: () => _openAddEdit(mountain),
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: mountain.featured
                            ? Icons.star
                            : Icons.star_border,
                        label: mountain.featured
                            ? 'Unfeature'
                            : 'Feature',
                        color: AppColors.accentGold,
                        onTap: () async {
                          await _service.toggleMountainFeatured(
                              mountain.id, !mountain.featured);
                        },
                        width: width,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Colors.red,
                        onTap: () => _delete(mountain),
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