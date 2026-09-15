import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _service.getBookingStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking(BookingModel b) async {
    final ok = await _service.confirmBooking(b.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '✅ Booking confirmed' : '❌ Failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      _loadStats();
    }
    // ⭐️ Send notification to user
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': b.userId,
      'title': '✅ Booking Confirmed!',
      'body': 'Your booking for "${b.itemName}" has been confirmed.',
      'type': 'booking',
      'category': 'success',
      'icon': '✅',
      'actionType': 'open_booking',
      'actionId': b.id,
      'isRead': false,
      'isPushed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  Future<void> _cancelBooking(BookingModel b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text('Are you sure you want to cancel booking for "${b.itemName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _service.cancelBooking(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '✅ Booking cancelled' : '❌ Failed'),
            backgroundColor: ok ? Colors.orange : Colors.red,
          ),
        );
        _loadStats();
      }
    }
  }

  Future<void> _completeBooking(BookingModel b) async {
    final ok = await _service.completeBooking(b.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '✅ Booking completed' : '❌ Failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      _loadStats();
    }
  }

  Future<void> _viewDetails(BookingModel b) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildDetailsSheet(b),
    );
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📅 Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // STATS
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Row(
              children: [
                _statBadge('Total', _stats['total'] ?? 0, Colors.white, width),
                _statBadge('Pending', _stats['pending'] ?? 0, Colors.orange, width),
                _statBadge('Confirmed', _stats['confirmed'] ?? 0, Colors.green, width),
                _statBadge('Cancelled', _stats['cancelled'] ?? 0, Colors.red, width),
              ],
            ),
          ),

          // SEARCH
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
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search bookings...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: height * 0.015),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'pending',
                      'confirmed',
                      'completed',
                      'cancelled'
                    ].map((status) {
                      final isSelected = _filterStatus == status;
                      return GestureDetector(
                        onTap: () => setState(() => _filterStatus = status),
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
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _service.getBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? [];
                final bookings = all.where((b) {
                  final matchSearch = _searchQuery.isEmpty ||
                      b.itemName.toLowerCase().contains(_searchQuery) ||
                      b.userName.toLowerCase().contains(_searchQuery);
                  final matchStatus = _filterStatus == 'all' ||
                      b.bookingStatus == _filterStatus;
                  return matchSearch && matchStatus;
                }).toList();

                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: width * 0.2, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Text(
                          'No bookings found',
                          style: TextStyle(
                              fontSize: width * 0.05,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: bookings.length,
                  itemBuilder: (context, i) =>
                      _buildCard(bookings[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int value, Color color, double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.005),
        padding: EdgeInsets.symmetric(vertical: width * 0.025),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.022,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BookingModel b, double width, double height) {
    Color statusColor;
    IconData statusIcon;
    switch (b.bookingStatus) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
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
          // Header strip
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.012),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: width * 0.05),
                SizedBox(width: width * 0.02),
                Text(
                  b.bookingStatus.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.03,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today,
                    size: width * 0.035, color: Colors.grey.shade500),
                SizedBox(width: width * 0.01),
                Text(
                  b.travelDate != null
                      ? '${b.travelDate!.day}/${b.travelDate!.month}/${b.travelDate!.year}'
                      : 'No date',
                  style: TextStyle(
                      fontSize: width * 0.028, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              children: [
                Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: width * 0.18,
                        height: width * 0.18,
                        child: b.itemImage.isNotEmpty
                            ? Image.network(b.itemImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            ))
                            : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.03),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              b.itemType.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            b.itemName,
                            style: TextStyle(
                              fontSize: width * 0.038,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: height * 0.005),
                          Row(
                            children: [
                              Icon(Icons.person,
                                  size: width * 0.03,
                                  color: Colors.grey.shade500),
                              SizedBox(width: width * 0.01),
                              Expanded(
                                child: Text(
                                  b.userName,
                                  style: TextStyle(
                                      fontSize: width * 0.028,
                                      color: Colors.grey.shade500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${b.currency} ${b.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${b.guests} guest${b.guests > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: width * 0.026,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: height * 0.015),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        icon: Icons.visibility,
                        label: 'View',
                        color: AppColors.primary,
                        onTap: () => _viewDetails(b),
                        width: width,
                      ),
                    ),
                    if (b.bookingStatus == 'pending') ...[
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.check,
                          label: 'Confirm',
                          color: Colors.green,
                          onTap: () => _confirmBooking(b),
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.close,
                          label: 'Cancel',
                          color: Colors.red,
                          onTap: () => _cancelBooking(b),
                          width: width,
                        ),
                      ),
                    ] else if (b.bookingStatus == 'confirmed') ...[
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.done_all,
                          label: 'Complete',
                          color: Colors.blue,
                          onTap: () => _completeBooking(b),
                          width: width,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.close,
                          label: 'Cancel',
                          color: Colors.red,
                          onTap: () => _cancelBooking(b),
                          width: width,
                        ),
                      ),
                    ],
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

  Widget _buildDetailsSheet(BookingModel b) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: height * 0.015),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: AppColors.primary, size: 28),
                    SizedBox(width: width * 0.03),
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking ID
                      _detailRow('Booking ID', b.id.substring(0, 8).toUpperCase(), width),

                      // Status
                      _detailRow('Status', b.bookingStatus.toUpperCase(), width),
                      _detailRow('Payment', b.paymentStatus.toUpperCase(), width),

                      const Divider(height: 30),

                      // Item
                      _sectionTitle('Item Details', width),
                      if (b.itemImage.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            b.itemImage,
                            height: height * 0.2,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: height * 0.015),
                      ],
                      _detailRow('Type', b.itemType.toUpperCase(), width),
                      _detailRow('Name', b.itemName, width),

                      const Divider(height: 30),

                      // Guest
                      _sectionTitle('Guest Info', width),
                      _detailRow('Name', b.userName, width),
                      _detailRow('Email', b.userEmail.isNotEmpty ? b.userEmail : 'N/A', width),
                      _detailRow('Phone', b.userPhone.isNotEmpty ? b.userPhone : 'N/A', width),

                      const Divider(height: 30),

                      // Travel
                      _sectionTitle('Travel Details', width),
                      _detailRow(
                        'Travel Date',
                        b.travelDate != null
                            ? '${b.travelDate!.day}/${b.travelDate!.month}/${b.travelDate!.year}'
                            : 'N/A',
                        width,
                      ),
                      _detailRow('Guests', b.guests.toString(), width),
                      _detailRow('Quantity', b.quantity.toString(), width),

                      const Divider(height: 30),

                      // Amount
                      _sectionTitle('Payment', width),
                      _detailRow('Amount', '${b.currency} ${b.amount.toStringAsFixed(2)}', width),
                      _detailRow('Method', b.paymentMethod.isNotEmpty ? b.paymentMethod : 'N/A', width),
                      _detailRow('Payment Status', b.paymentStatus.toUpperCase(), width),

                      if (b.specialRequests.isNotEmpty) ...[
                        const Divider(height: 30),
                        _sectionTitle('Special Requests', width),
                        Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(b.specialRequests),
                        ),
                      ],

                      const Divider(height: 30),

                      // Actions
                      _sectionTitle('Contact', width),
                      SizedBox(height: height * 0.01),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (b.userPhone.isNotEmpty) {
                                  final uri = Uri.parse('tel:${b.userPhone}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                            ),
                          ),
                          SizedBox(width: width * 0.03),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (b.userEmail.isNotEmpty) {
                                  final uri = Uri.parse('mailto:${b.userEmail}');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              },
                              icon: const Icon(Icons.email),
                              label: const Text('Email'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.03),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: width * 0.04,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width * 0.3,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: width * 0.032,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: width * 0.032,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}