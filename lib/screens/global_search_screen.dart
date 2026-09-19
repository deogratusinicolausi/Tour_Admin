import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/global_search_service.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../utils/colors.dart';
import 'destinations_list_screen.dart';
import 'hotels_list_screen.dart';
import 'tours_list_screen.dart';
import 'activities_list_screen.dart';
import 'deals_list_screen.dart';
import 'bookings_list_screen.dart';
import 'users_list_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  final _searchService = GlobalSearchService();

  Map<String, List<Map<String, dynamic>>> _results = {};
  bool _isSearching = false;
  bool _hasSearched = false;

  final List<String> _filterCategories = [
    'all',
    'destinations',
    'hotels',
    'tours',
    'activities',
    'deals',
    'bookings',
    'users',
  ];
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = {};
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await _searchService.searchAll(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  int get _totalResults => _searchService.getTotalCount(_results);

  List<Map<String, dynamic>> get _displayedResults {
    if (_selectedFilter == 'all') {
      final all = <Map<String, dynamic>>[];
      _results.forEach((key, value) => all.addAll(value));
      return all;
    }
    return _results[_selectedFilter] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('🔍 ${context.tr('global_search')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => _performSearch(v),
                decoration: InputDecoration(
                  hintText: context.tr('search_hint'),
                  prefixIcon: const Icon(Icons.search, size: 24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: height * 0.02),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),

          // FILTER CHIPS
          if (_hasSearched && _totalResults > 0)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, vertical: height * 0.01),
              color: AppColors.primary,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterCategories.map((cat) {
                    final isSelected = _selectedFilter == cat;
                    final count = cat == 'all'
                        ? _totalResults
                        : (_results[cat]?.length ?? 0);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = cat),
                      child: Container(
                        margin: EdgeInsets.only(right: width * 0.02),
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.035,
                          vertical: height * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentGold
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              context.tr(cat).toUpperCase(),
                              style: TextStyle(
                                color:
                                isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.026,
                              ),
                            ),
                            if (count > 0) ...[
                              SizedBox(width: width * 0.015),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.015,
                                    vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontSize: width * 0.022,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // RESULTS
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                ? _buildEmptyState(width)
                : _totalResults == 0
                ? _buildNoResults(width)
                : _buildResults(width, height),
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
          Icon(Icons.search, size: width * 0.25, color: context.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            context.tr('search_anything'),
            style: TextStyle(
              fontSize: width * 0.06,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.15),
            child: Text(
              context.tr('search_description'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _quickChip('🏨 hotels', width),
              _quickChip('🦁 tours', width),
              _quickChip('👥 users', width),
              _quickChip('📅 bookings', width),
              _quickChip('🎁 deals', width),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String text, double width) {
    return GestureDetector(
      onTap: () {
        final query = text.substring(2);
        _searchController.text = query;
        _performSearch(query);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: width * 0.035, vertical: width * 0.02),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.textSecondary.withOpacity(0.2)),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: context.textPrimary)),
      ),
    );
  }

  Widget _buildNoResults(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: width * 0.2, color: context.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            context.tr('no_results'),
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('try_different_keywords'),
            style: TextStyle(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(double width, double height) {
    final results = _displayedResults;

    return ListView.builder(
      padding: EdgeInsets.all(width * 0.04),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final item = results[i];
        return _buildResultCard(item, width, height);
      },
    );
  }

  Widget _buildResultCard(
      Map<String, dynamic> item, double width, double height) {
    final type = item['type'] as String? ?? '';
    final title = _getTitle(item, type);
    final subtitle = _getSubtitle(item, type);
    final icon = _getIcon(type);
    final color = _getColor(type);

    return GestureDetector(
      onTap: () => _navigateToType(type),
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.012),
        padding: EdgeInsets.all(width * 0.035),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(icon, style: TextStyle(fontSize: width * 0.06)),
            ),
            SizedBox(width: width * 0.03),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.tr(type).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.038,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: height * 0.003),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: width * 0.028,
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: width * 0.035,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(Map<String, dynamic> item, String type) {
    if (type == 'deals') return item['title'] ?? 'Untitled Deal';
    return item['name'] ?? item['itemName'] ?? 'Untitled';
  }

  String _getSubtitle(Map<String, dynamic> item, String type) {
    switch (type) {
      case 'destinations':
        return '${item['location'] ?? ''} ${item['country'] ?? ''}'.trim();
      case 'hotels':
      case 'tours':
      case 'activities':
        return item['location'] ?? item['destinationName'] ?? '';
      case 'deals':
        return item['itemName'] ?? '';
      case 'bookings':
        return 'Guest: ${item['userName'] ?? 'Unknown'}';
      case 'users':
        return item['email'] ?? '';
      default:
        return '';
    }
  }

  String _getIcon(String type) {
    switch (type) {
      case 'destinations':
        return '📍';
      case 'hotels':
        return '🏨';
      case 'tours':
        return '🦁';
      case 'activities':
        return '🎯';
      case 'deals':
        return '🎁';
      case 'bookings':
        return '📅';
      case 'users':
        return '👥';
      default:
        return '📄';
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'destinations':
        return const Color(0xFF4facfe);
      case 'hotels':
        return const Color(0xFF43e97b);
      case 'tours':
        return const Color(0xFFfa709a);
      case 'activities':
        return const Color(0xFFff9a9e);
      case 'deals':
        return const Color(0xFFf093fb);
      case 'bookings':
        return const Color(0xFF667eea);
      case 'users':
        return const Color(0xFF38f9d7);
      default:
        return AppColors.primary;
    }
  }

  void _navigateToType(String type) {
    Widget? screen;
    switch (type) {
      case 'destinations':
        screen = const DestinationsListScreen();
        break;
      case 'hotels':
        screen = const HotelsListScreen();
        break;
      case 'tours':
        screen = const ToursListScreen();
        break;
      case 'activities':
        screen = const ActivitiesListScreen();
        break;
      case 'deals':
        screen = const DealsListScreen();
        break;
      case 'bookings':
        screen = const BookingsListScreen();
        break;
      case 'users':
        screen = const UsersListScreen();
        break;
    }
    if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }
}