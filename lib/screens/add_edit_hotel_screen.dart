import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/hotel_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';

class AddEditHotelScreen extends StatefulWidget {
  final HotelModel? hotel;

  const AddEditHotelScreen({super.key, this.hotel});

  @override
  State<AddEditHotelScreen> createState() => _AddEditHotelScreenState();
}

class _AddEditHotelScreenState extends State<AddEditHotelScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  String _currency = 'USD';
  String _destinationId = '';
  String _destinationName = '';
  String _imageUrl = '';
  List<String> _gallery = [];
  List<String> _facilities = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  List<Map<String, dynamic>> _destinations = [];

  final List<Map<String, dynamic>> _availableFacilities = [
    {'icon': '📶', 'name': 'WiFi'},
    {'icon': '🏊', 'name': 'Pool'},
    {'icon': '💆', 'name': 'Spa'},
    {'icon': '🏋️', 'name': 'Gym'},
    {'icon': '🍽️', 'name': 'Restaurant'},
    {'icon': '🍺', 'name': 'Bar'},
    {'icon': '🚗', 'name': 'Parking'},
    {'icon': '❄️', 'name': 'AC'},
    {'icon': '🐕', 'name': 'Pet Friendly'},
    {'icon': '🛎️', 'name': 'Room Service'},
    {'icon': '🎾', 'name': 'Tennis'},
    {'icon': '🏖️', 'name': 'Beach Access'},
  ];

  bool get isEditing => widget.hotel != null;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    if (isEditing) _loadHotel();
  }

  void _loadHotel() {
    final h = widget.hotel!;
    _nameController.text = h.name;
    _descriptionController.text = h.description;
    _locationController.text = h.location;
    _priceController.text = h.priceFrom.toString();
    _phoneController.text = h.contactPhone;
    _emailController.text = h.contactEmail;
    _websiteController.text = h.website;
    _currency = h.currency;
    _destinationId = h.destinationId;
    _destinationName = h.destinationName;
    _imageUrl = h.imageUrl;
    _gallery = List.from(h.gallery);
    _facilities = List.from(h.facilities);
    _rating = h.rating;
    _featured = h.featured;
    _status = h.status;
  }

  Future<void> _loadDestinations() async {
    final list = await _firestoreService.getDestinationsForDropdown();
    if (mounted) setState(() => _destinations = list);
  }

  Future<void> _pickAndUploadImage({bool isMain = true}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      String? url;

      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinaryService.uploadImageBytes(
          bytes,
          folder: 'turiva/hotels',
        );
      } else {
        url = await _cloudinaryService.uploadImage(
          File(pickedFile.path),
          folder: 'turiva/hotels',
        );
      }

      if (url != null) {
        setState(() {
          if (isMain) {
            _imageUrl = url!;
          } else {
            _gallery.add(url!);
          }
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a main image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final hotel = HotelModel(
      id: widget.hotel?.id ?? '',
      name: _nameController.text.trim(),
      destinationId: _destinationId,
      destinationName: _destinationName,
      description: _descriptionController.text.trim(),
      priceFrom: double.tryParse(_priceController.text) ?? 0.0,
      currency: _currency,
      facilities: _facilities,
      imageUrl: _imageUrl,
      gallery: _gallery,
      rating: _rating,
      location: _locationController.text.trim(),
      status: _status,
      featured: _featured,
      contactPhone: _phoneController.text.trim(),
      contactEmail: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      createdAt: widget.hotel?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _firestoreService.updateHotel(hotel);
    } else {
      final id = await _firestoreService.addHotel(hotel);
      success = id != null;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isEditing ? '✅ Hotel updated!' : '✅ Hotel added!')
              : '❌ Failed to save'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? '✏️ ${context.tr('edit_hotel')}' : '➕ ${context.tr('add_hotel')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MAIN IMAGE
              _buildSectionTitle('📸 ${context.tr('main_image')}', width),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap: _isUploading
                    ? null
                    : () => _pickAndUploadImage(isMain: true),
                child: Container(
                  height: height * 0.25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageUrl.isEmpty
                          ? Colors.grey.shade300
                          : AppColors.primary,
                      width: 2,
                    ),
                    image: _imageUrl.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(_imageUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrl.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: width * 0.15,
                          color: Colors.grey.shade400),
                      SizedBox(height: height * 0.01),
                      Text(
                        context.tr('tap_to_upload_image'),
                        style:
                        TextStyle(color: context.textSecondary),
                      ),
                    ],
                  )
                      : null,
                ),
              ),
              SizedBox(height: height * 0.025),

              // GALLERY
              _buildSectionTitle('🖼️ ${context.tr('gallery_optional')}', width),
              SizedBox(height: height * 0.01),
              SizedBox(
                height: height * 0.12,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gallery.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _gallery.length) {
                      return GestureDetector(
                        onTap: _isUploading
                            ? null
                            : () => _pickAndUploadImage(isMain: false),
                        child: Container(
                          width: height * 0.12,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(Icons.add,
                              color: Colors.grey.shade400,
                              size: width * 0.08),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: height * 0.12,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_gallery[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _gallery.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: height * 0.025),

              // BASIC INFO
              _buildSectionTitle('📝 ${context.tr('basic_info')}', width),
              SizedBox(height: height * 0.01),

              _buildTextField(
                controller: _nameController,
                label: context.tr('hotel_name'),
                icon: Icons.hotel,
                validator: (v) => v!.isEmpty ? context.tr('name_required') : null,
              ),
              SizedBox(height: height * 0.015),

              // Destination Dropdown
              DropdownButtonFormField<String>(
                value: _destinationId.isEmpty ? null : _destinationId,
                decoration: InputDecoration(
                  labelText: context.tr('destination'),
                  prefixIcon: const Icon(Icons.place),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _destinations.map((d) {
                  return DropdownMenuItem<String>(
                    value: d['id'],
                    child: Text(d['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final dest = _destinations
                        .firstWhere((d) => d['id'] == value);
                    setState(() {
                      _destinationId = value;
                      _destinationName = dest['name'] ?? '';
                    });
                  }
                },
              ),
              SizedBox(height: height * 0.015),

              _buildTextField(
                controller: _locationController,
                label: context.tr('location'),
                icon: Icons.location_on,
              ),
              SizedBox(height: height * 0.015),

              _buildTextField(
                controller: _descriptionController,
                label: context.tr('description'),
                icon: Icons.description,
                maxLines: 4,
              ),
              SizedBox(height: height * 0.025),

              // PRICE
              _buildSectionTitle('💰 ${context.tr('pricing')}', width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _priceController,
                      label: context.tr('price_from'),
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? context.tr('price_required') : null,
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03, vertical: height * 0.02),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['USD', 'TZS', 'EUR', 'GBP']
                            .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'USD'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // FACILITIES
              _buildSectionTitle('🏨 ${context.tr('facilities')}', width),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableFacilities.map((f) {
                    final isSelected =
                    _facilities.contains(f['name'] as String);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _facilities.remove(f['name']);
                          } else {
                            _facilities.add(f['name'] as String);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(f['icon'] as String),
                            const SizedBox(width: 5),
                            Text(
                              f['name'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: height * 0.025),

              // CONTACT
              _buildSectionTitle('📞 ${context.tr('contact_info')}', width),
              SizedBox(height: height * 0.01),
              _buildTextField(
                controller: _phoneController,
                label: context.tr('phone'),
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: height * 0.015),
              _buildTextField(
                controller: _emailController,
                label: context.tr('email'),
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: height * 0.015),
              _buildTextField(
                controller: _websiteController,
                label: context.tr('website'),
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: height * 0.025),

              // RATING
              _buildSectionTitle('⭐ ${context.tr('rating')}', width),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.accentGold,
                            size: 32,
                          ),
                          onPressed: () =>
                              setState(() => _rating = index + 1.0),
                        );
                      }),
                    ),
                    Text(
                      '${_rating.toStringAsFixed(1)} ${context.tr('stars')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.025),

              // SETTINGS
              _buildSectionTitle('⚙️ ${context.tr('settings')}', width),
              SizedBox(height: height * 0.01),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text('⭐ ${context.tr('featured')}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(context.tr('show_on_homepage')),
                  value: _featured,
                  activeColor: AppColors.accentGold,
                  onChanged: (v) => setState(() => _featured = v),
                ),
              ),
              SizedBox(height: height * 0.015),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('status'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: height * 0.01),
                    Row(
                      children: ['active', 'inactive'].map((s) {
                        final isSelected = _status == s;
                        return GestureDetector(
                          onTap: () => setState(() => _status = s),
                          child: Container(
                            margin: EdgeInsets.only(right: width * 0.03),
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.05,
                              vertical: height * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (s == 'active'
                                  ? Colors.green
                                  : Colors.grey)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s.toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.03,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.03),

              // SAVE
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isEditing ? context.tr('update_hotel').toUpperCase() : context.tr('add_hotel').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.04,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}