import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/destination_model.dart';
import '../models/hotel_model.dart';
import '../models/tour_model.dart';
import '../models/activity_model.dart';
import '../models/deal_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../models/beach_model.dart';
import '../models/mountain_model.dart';
import '../models/culture_model.dart';
import '../models/food_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ ===== DESTINATIONS CRUD =====

  // CREATE
  Future<String?> addDestination(DestinationModel destination) async {
    try {
      DocumentReference ref = await _firestore
          .collection('destinations')
          .add(destination.toMap());
      print('✅ Destination added: ${ref.id}');
      return ref.id;
    } catch (e) {
      print('🔥 Error adding destination: $e');
      return null;
    }
  }

  // ⭐️ ===== HOTELS CRUD =====

  Future<String?> addHotel(HotelModel hotel) async {
    try {
      DocumentReference ref =
      await _firestore.collection('hotels').add(hotel.toMap());
      print('✅ Hotel added: ${ref.id}');
      return ref.id;
    } catch (e) {
      print('🔥 Error adding hotel: $e');
      return null;
    }
  }


  // ⭐️ ===== TOURS CRUD =====

  Future<String?> addTour(TourModel tour) async {
    try {
      DocumentReference ref =
      await _firestore.collection('tours').add(tour.toMap());
      print('✅ Tour added: ${ref.id}');
      return ref.id;
    } catch (e) {
      print('🔥 Error adding tour: $e');
      return null;
    }
  }


  // ⭐️ ===== BEACHES CRUD =====

  Future<String?> addBeach(BeachModel beach) async {
    try {
      DocumentReference ref =
      await _firestore.collection('beaches').add(beach.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error adding beach: $e');
      return null;
    }
  }

  Stream<List<BeachModel>> getBeaches() {
    return _firestore
        .collection('beaches')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BeachModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Future<bool> updateBeach(BeachModel beach) async {
    try {
      await _firestore
          .collection('beaches')
          .doc(beach.id)
          .update(beach.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBeach(String id) async {
    try {
      await _firestore.collection('beaches').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleBeachFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('beaches').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }



  // ⭐️ ===== MOUNTAINS CRUD =====

  Future<String?> addMountain(MountainModel mountain) async {
    try {
      DocumentReference ref =
      await _firestore.collection('mountains').add(mountain.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error adding mountain: $e');
      return null;
    }
  }

  Stream<List<MountainModel>> getMountains() {
    return _firestore
        .collection('mountains')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MountainModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Future<bool> updateMountain(MountainModel mountain) async {
    try {
      await _firestore
          .collection('mountains')
          .doc(mountain.id)
          .update(mountain.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMountain(String id) async {
    try {
      await _firestore.collection('mountains').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleMountainFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('mountains').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }



  // ⭐️ ===== CULTURE CRUD =====

  Future<String?> addCulture(CultureModel culture) async {
    try {
      DocumentReference ref =
      await _firestore.collection('culture').add(culture.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error adding culture: $e');
      return null;
    }
  }

  Stream<List<CultureModel>> getCulture() {
    return _firestore
        .collection('culture')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CultureModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Future<bool> updateCulture(CultureModel culture) async {
    try {
      await _firestore
          .collection('culture')
          .doc(culture.id)
          .update(culture.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCulture(String id) async {
    try {
      await _firestore.collection('culture').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleCultureFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('culture').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }



  // ⭐️ ===== FOOD CRUD =====

  Future<String?> addFood(FoodModel food) async {
    try {
      DocumentReference ref =
      await _firestore.collection('food').add(food.toMap());
      return ref.id;
    } catch (e) {
      print('🔥 Error adding food: $e');
      return null;
    }
  }

  Stream<List<FoodModel>> getFood() {
    return _firestore
        .collection('food')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Future<bool> updateFood(FoodModel food) async {
    try {
      await _firestore
          .collection('food')
          .doc(food.id)
          .update(food.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFood(String id) async {
    try {
      await _firestore.collection('food').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleFoodFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('food').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }


  // ⭐️ ===== ACTIVITIES CRUD =====

  Future<String?> addActivity(ActivityModel activity) async {
    try {
      DocumentReference ref =
      await _firestore.collection('activities').add(activity.toMap());
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  Stream<List<ActivityModel>> getActivities() {
    return _firestore
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList());
  }


  // ⭐️ ===== BOOKINGS =====

  Stream<List<BookingModel>> getBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<BookingModel>> getBookingsByStatus(String status) {
    return _firestore
        .collection('bookings')
        .where('bookingStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ⭐️ ===== USERS =====

  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get user stats
  Future<Map<String, int>> getUserStats() async {
    try {
      final all = await _firestore.collection('users').get();
      int customers = 0;
      int admins = 0;
      int banned = 0;
      int active = 0;

      for (var doc in all.docs) {
        final data = doc.data();
        final role = data['role'] ?? 'customer';
        final status = data['status'] ?? 'active';

        if (role == 'customer') customers++;
        else if (role == 'admin' || role == 'superAdmin') admins++;

        if (status == 'banned') banned++;
        else if (status == 'active') active++;
      }

      return {
        'total': all.docs.length,
        'customers': customers,
        'admins': admins,
        'banned': banned,
        'active': active,
      };
    } catch (e) {
      return {'total': 0, 'customers': 0, 'admins': 0, 'banned': 0, 'active': 0};
    }
  }

  Future<bool> updateBookingStatus(
      String id, String bookingStatus, String paymentStatus) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'bookingStatus': bookingStatus,
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmBooking(String id) async {
    return updateBookingStatus(id, 'confirmed', 'paid');
  }

  Future<bool> cancelBooking(String id) async {
    return updateBookingStatus(id, 'cancelled', 'refunded');
  }

  Future<bool> completeBooking(String id) async {
    return updateBookingStatus(id, 'completed', 'paid');
  }

  Future<bool> updateAdminNotes(String id, String notes) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'adminNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBooking(String id) async {
    try {
      await _firestore.collection('bookings').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get booking stats
  Future<Map<String, int>> getBookingStats() async {
    try {
      final all = await _firestore.collection('bookings').get();
      int pending = 0;
      int confirmed = 0;
      int cancelled = 0;
      int completed = 0;
      double totalRevenue = 0;

      for (var doc in all.docs) {
        final data = doc.data();
        final status = data['bookingStatus'] ?? 'pending';
        final amount = (data['amount'] ?? 0.0).toDouble();

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            totalRevenue += amount;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'completed':
            completed++;
            totalRevenue += amount;
            break;
        }
      }

      return {
        'total': all.docs.length,
        'pending': pending,
        'confirmed': confirmed,
        'cancelled': cancelled,
        'completed': completed,
        'revenue': totalRevenue.toInt(),
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'cancelled': 0,
        'completed': 0,
        'revenue': 0,
      };
    }
  }

  Future<bool> updateActivity(ActivityModel activity) async {
    try {
      await _firestore
          .collection('activities')
          .doc(activity.id)
          .update(activity.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await _firestore.collection('activities').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleActivityFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('activities').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ ===== DEALS CRUD =====

  Future<String?> addDeal(DealModel deal) async {
    try {
      DocumentReference ref =
      await _firestore.collection('deals').add(deal.toMap());
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  Stream<List<DealModel>> getDeals() {
    return _firestore
        .collection('deals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DealModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<bool> updateDeal(DealModel deal) async {
    try {
      await _firestore.collection('deals').doc(deal.id).update(deal.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDeal(String id) async {
    try {
      await _firestore.collection('deals').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleDealFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('deals').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<TourModel>> getTours() {
    return _firestore
        .collection('tours')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TourModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<bool> updateTour(TourModel tour) async {
    try {
      await _firestore.collection('tours').doc(tour.id).update(tour.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTour(String id) async {
    try {
      await _firestore.collection('tours').doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleTourFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('tours').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<HotelModel>> getHotels() {
    return _firestore
        .collection('hotels')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HotelModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<HotelModel?> getHotel(String id) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('hotels').doc(id).get();
      if (doc.exists) {
        return HotelModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('🔥 Error getting hotel: $e');
      return null;
    }
  }

  Future<bool> updateHotel(HotelModel hotel) async {
    try {
      await _firestore
          .collection('hotels')
          .doc(hotel.id)
          .update(hotel.toMap());
      print('✅ Hotel updated');
      return true;
    } catch (e) {
      print('🔥 Error updating hotel: $e');
      return false;
    }
  }

  Future<bool> deleteHotel(String id) async {
    try {
      await _firestore.collection('hotels').doc(id).delete();
      print('✅ Hotel deleted');
      return true;
    } catch (e) {
      print('🔥 Error deleting hotel: $e');
      return false;
    }
  }

  Future<bool> toggleHotelFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('hotels').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ Get destinations for dropdown
  Future<List<Map<String, dynamic>>> getDestinationsForDropdown() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('destinations').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // READ ALL
  Stream<List<DestinationModel>> getDestinations() {
    return _firestore
        .collection('destinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DestinationModel.fromMap(
      doc.data(),
      doc.id,
    ))
        .toList());
  }

  // READ ONE
  Future<DestinationModel?> getDestination(String id) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('destinations').doc(id).get();
      if (doc.exists) {
        return DestinationModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('🔥 Error getting destination: $e');
      return null;
    }
  }

  // UPDATE
  Future<bool> updateDestination(DestinationModel destination) async {
    try {
      await _firestore
          .collection('destinations')
          .doc(destination.id)
          .update(destination.toMap());
      print('✅ Destination updated');
      return true;
    } catch (e) {
      print('🔥 Error updating destination: $e');
      return false;
    }
  }

  // DELETE
  Future<bool> deleteDestination(String id) async {
    try {
      await _firestore.collection('destinations').doc(id).delete();
      print('✅ Destination deleted');
      return true;
    } catch (e) {
      print('🔥 Error deleting destination: $e');
      return false;
    }
  }

  // TOGGLE FEATURED
  Future<bool> toggleFeatured(String id, bool featured) async {
    try {
      await _firestore.collection('destinations').doc(id).update({
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // TOGGLE STATUS
  Future<bool> toggleStatus(String id, String status) async {
    try {
      await _firestore.collection('destinations').doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

}