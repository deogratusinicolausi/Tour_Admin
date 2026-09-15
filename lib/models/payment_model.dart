import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String bookingId;
  final String itemId;
  final String itemType;
  final String itemName;
  final double amount;
  final String currency;
  final String method; // cash, mpesa, tigopesa, airtel, bank, card
  final String status; // pending, completed, failed, refunded
  final String transactionId;
  final String reference;
  final String notes;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.userPhone = '',
    this.bookingId = '',
    this.itemId = '',
    this.itemType = '',
    this.itemName = '',
    required this.amount,
    this.currency = 'USD',
    this.method = 'cash',
    this.status = 'pending',
    this.transactionId = '',
    this.reference = '',
    this.notes = '',
    this.paidAt,
    this.refundedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      bookingId: map['bookingId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemName: map['itemName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      method: map['method'] ?? 'cash',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'] ?? '',
      reference: map['reference'] ?? '',
      notes: map['notes'] ?? '',
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      refundedAt: (map['refundedAt'] as Timestamp?)?.toDate(),
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
      'bookingId': bookingId,
      'itemId': itemId,
      'itemType': itemType,
      'itemName': itemName,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'reference': reference,
      'notes': notes,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'refundedAt':
      refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get timeAgo {
    if (createdAt == null) return 'just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}