import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String itemType; // hotel, tour, activity, deal
  final String itemId;
  final String itemName;
  final String itemImage;
  final DateTime? travelDate;
  final int quantity;
  final int guests;
  final double amount;
  final String currency;
  final String paymentStatus; // pending, paid, refunded
  final String bookingStatus; // pending, confirmed, cancelled, completed
  final String paymentMethod;
  final String specialRequests;
  final String adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.userPhone = '',
    required this.itemType,
    required this.itemId,
    required this.itemName,
    this.itemImage = '',
    this.travelDate,
    this.quantity = 1,
    this.guests = 1,
    required this.amount,
    this.currency = 'USD',
    this.paymentStatus = 'pending',
    this.bookingStatus = 'pending',
    this.paymentMethod = '',
    this.specialRequests = '',
    this.adminNotes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Guest',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      itemType: map['itemType'] ?? 'tour',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? 'Unknown',
      itemImage: map['itemImage'] ?? '',
      travelDate: (map['travelDate'] as Timestamp?)?.toDate(),
      quantity: map['quantity'] ?? 1,
      guests: map['guests'] ?? 1,
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      bookingStatus: map['bookingStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      specialRequests: map['specialRequests'] ?? '',
      adminNotes: map['adminNotes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'itemType': itemType,
      'itemId': itemId,
      'itemName': itemName,
      'itemImage': itemImage,
      'travelDate': travelDate != null
          ? Timestamp.fromDate(travelDate!)
          : null,
      'quantity': quantity,
      'guests': guests,
      'amount': amount,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'paymentMethod': paymentMethod,
      'specialRequests': specialRequests,
      'adminNotes': adminNotes,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BookingModel copyWith({
    String? bookingStatus,
    String? paymentStatus,
    String? adminNotes,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      itemType: itemType,
      itemId: itemId,
      itemName: itemName,
      itemImage: itemImage,
      travelDate: travelDate,
      quantity: quantity,
      guests: guests,
      amount: amount,
      currency: currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentMethod: paymentMethod,
      specialRequests: specialRequests,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}