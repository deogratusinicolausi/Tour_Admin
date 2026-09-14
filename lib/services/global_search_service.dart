import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ Search across ALL collections
  Future<Map<String, List<Map<String, dynamic>>>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return {
        'destinations': [],
        'hotels': [],
        'tours': [],
        'activities': [],
        'deals': [],
        'bookings': [],
        'users': [],
      };
    }

    final q = query.toLowerCase().trim();

    // Run all searches in parallel
    final results = await Future.wait([
      _searchCollection('destinations', q, ['name', 'country', 'location']),
      _searchCollection('hotels', q, ['name', 'location', 'destinationName']),
      _searchCollection('tours', q, ['name', 'destinationName']),
      _searchCollection('activities', q, ['name', 'destinationName']),
      _searchCollection('deals', q, ['title', 'itemName']),
      _searchCollection('bookings', q, ['itemName', 'userName', 'userEmail']),
      _searchCollection('users', q, ['name', 'email']),
    ]);

    return {
      'destinations': results[0],
      'hotels': results[1],
      'tours': results[2],
      'activities': results[3],
      'deals': results[4],
      'bookings': results[5],
      'users': results[6],
    };
  }

  Future<List<Map<String, dynamic>>> _searchCollection(
      String collection,
      String query,
      List<String> searchFields,
      ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .limit(20)
          .get();

      final results = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        for (String field in searchFields) {
          final value = data[field]?.toString().toLowerCase() ?? '';
          if (value.contains(query)) {
            results.add({
              'id': doc.id,
              'type': collection,
              ...data,
            });
            break;
          }
        }
      }

      return results;
    } catch (e) {
      print('🔥 Error searching $collection: $e');
      return [];
    }
  }

  // ⭐️ Get total count of results
  int getTotalCount(Map<String, List<Map<String, dynamic>>> results) {
    return results.values.fold(0, (sum, list) => sum + list.length);
  }
}