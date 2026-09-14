import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/tour_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';

class AddEditTourScreen extends StatefulWidget {
  final TourModel? tour;

  const AddEditTourScreen({super.key, this.tour});

  @override
  State<AddEditTourScreen> createState() => _AddEditTourScreenState();
}

class _AddEditTourScreenState extends State<AddEditTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxPeopleController = TextEditingController(text: '10');

  final _itineraryController = TextEditingController();
  final _includedController = TextEditingController();
  final _excludedController = TextEditingController();

  String _currency = 'USD';
  String _destinationId = '';
  String _destinationName = '';
  String _tourType = 'Safari';
  List<String> _images = [];
  List<String> _itinerary = [];
  List<String> _included = [];
  List<String> _excluded = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  List<Map<String, dynamic>> _destinations = [];

  final List<Map<String, String>> _tourTypes = [
    {'icon': '🦁', 'name': 'Safari'},
    {'icon': '⛰️', 'name': 'Hiking'},
    {'icon': '🏖️', 'name': 'Beach'},
    {'icon': '🎭', 'name': 'Cultural'},
    {'icon': '🚙', 'name': 'Adventure'},
    {'icon': '📸', 'name': 'Photography'},
    {'icon': '🐦', 'name': 'Birding'},
    {'icon': '🚁', 'name': 'Helicopter'},
  ];

  bool get isEditing => widget.tour != null;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    if (isEditing) _loadTour();
  }

  void _loadTour() {
    final t = widget.tour!;
    _nameController.text = t.name;
    _descriptionController.text = t.description;
    _priceController.text = t.price.toString();
    _durationController.text = t.duration;
    _maxPeopleController.text = t.maxPeople.toString();
    _currency = t.currency;
    _destinationId = t.destinationId;
    _destinationName = t.destinationName;
    _tourType = t.tourType;
    _images = List.from(t.images);
    _itinerary = List.from(t.itinerary);
    _included = List.from(t.included);
    _excluded = List.from(t.excluded);
    _rating = t.rating;
    _featured = t.featured;
    _status = t.status;
  }

  Future<void> _loadDestinations() async {
    final list = await _firestoreService.getDestinationsForDropdown();
    if (mounted) setState(() => _destinations = list);
  }

  Future<void> _pickAndUploadImage() async {
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
          folder: 'turiva/tours',
        );
      } else {
        url = await _cloudinaryService.uploadImage(
          File(pickedFile.path),
          folder: 'turiva/tours',
        );
      }

      if (url != null) {
        setState(() {
          _images.add(url!);
          _isUploading = false;
        });
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  void _addToList(
      TextEditingController controller, List<String> list) {
    if (controller.text.trim().isEmpty) return;
    setState(() {
      list.add(controller.text.trim());
      controller.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final tour = TourModel(
      id: widget.tour?.id ?? '',
      name: _nameController.text.trim(),
      destinationId: _destinationId,
      destinationName: _destinationName,
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      currency: _currency,
      duration: _durationController.text.trim(),
      images: _images,
      itinerary: _itinerary,
      included: _included,
      excluded: _excluded,
      rating: _rating,
      featured: _featured,
      status: _status,
      tourType: _tourType,
      maxPeople: int.tryParse(_maxPeopleController.text) ?? 10,
      createdAt: widget.tour?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _firestoreService.updateTour(tour);
    } else {
      final id = await _firestoreService.addTour(tour);
      success = id != null;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isEditing ? '✅ Tour updated!' : '✅ Tour added!')
              : '❌ Failed'),
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
    _priceController.dispose();
    _durationController.dispose();
    _maxPeopleController.dispose();
    _itineraryController.dispose();
    _includedController.dispose();
    _excludedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? '✏️ Edit Tour' : '➕ Add Tour'),
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
              // IMAGES
              _buildSectionTitle('📸 Tour Images', width),
              SizedBox(height: height * 0.01),
              SizedBox(
                height: height * 0.15,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      return GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: Container(
                          width: height * 0.15,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _isUploading
                              ? const Center(
                              child: CircularProgressIndicator())
                              : Icon(Icons.add_photo_alternate,
                              color: Colors.grey.shade400,
                              size: width * 0.1),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: height * 0.15,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_images[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _images.removeAt(index)),
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
              _buildSectionTitle('📝 Basic Information', width),
              SizedBox(height: height * 0.01),

              _buildTextField(
                controller: _nameController,
                label: 'Tour Name',
                icon: Icons.tour,
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              SizedBox(height: height * 0.015),

              DropdownButtonFormField<String>(
                value: _destinationId.isEmpty ? null : _destinationId,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: const Icon(Icons.place),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _destinations.map((d) {
                  return DropdownMenuItem<String>(
                    value: d['id'] as String,
                    child: Text(d['name'] as String? ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final dest =
                    _destinations.firstWhere((d) => d['id'] == value);
                    setState(() {
                      _destinationId = value;
                      _destinationName = dest['name'] as String? ?? '';
                    });
                  }
                },
              ),
              SizedBox(height: height * 0.015),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 4,
              ),
              SizedBox(height: height * 0.025),

              // TOUR TYPE
              _buildSectionTitle('🎯 Tour Type', width),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tourTypes.map((type) {
                    final isSelected = _tourType == type['name'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _tourType = type['name']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type['icon']!),
                            const SizedBox(width: 5),
                            Text(
                              type['name']!,
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

              // PRICING & DURATION
              _buildSectionTitle('💰 Pricing & Duration', width),
              SizedBox(height: height * 0.01),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Price required' : null,
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03, vertical: height * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['USD', 'TZS', 'EUR', 'GBP']
                            .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'USD'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _durationController,
                      label: 'Duration',
                      icon: Icons.access_time,
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPeopleController,
                      label: 'Max People',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // ITINERARY
              _buildSectionTitle('🗺️ Itinerary', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _itineraryController,
                items: _itinerary,
                hint: 'Day 1: Arrival & Welcome',
                icon: Icons.map,
                onAdd: () => _addToList(_itineraryController, _itinerary),
                onRemove: (i) =>
                    setState(() => _itinerary.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // INCLUDED
              _buildSectionTitle('✅ What\'s Included', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _includedController,
                items: _included,
                hint: 'Accommodation, Meals, Guide',
                icon: Icons.check_circle,
                color: Colors.green,
                onAdd: () => _addToList(_includedController, _included),
                onRemove: (i) =>
                    setState(() => _included.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // EXCLUDED
              _buildSectionTitle('❌ What\'s Not Included', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _excludedController,
                items: _excluded,
                hint: 'Flights, Insurance, Tips',
                icon: Icons.cancel,
                color: Colors.red,
                onAdd: () => _addToList(_excludedController, _excluded),
                onRemove: (i) =>
                    setState(() => _excluded.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // RATING
              _buildSectionTitle('⭐ Rating', width),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
              ),
              SizedBox(height: height * 0.025),

              // SETTINGS
              _buildSectionTitle('⚙️ Settings', width),
              SizedBox(height: height * 0.01),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('⭐ Featured',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _featured,
                  activeColor: AppColors.accentGold,
                  onChanged: (v) => setState(() => _featured = v),
                ),
              ),
              SizedBox(height: height * 0.015),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
                              ? (s == 'active' ? Colors.green : Colors.grey)
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
                    isEditing ? 'UPDATE TOUR' : 'ADD TOUR',
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

  Widget _buildListBuilder({
    required TextEditingController controller,
    required List<String> items,
    required String hint,
    required IconData icon,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required double width,
    required double height,
    Color? color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, color: color),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: width * 0.02),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              iconSize: 32,
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          SizedBox(height: height * 0.01),
          ...items.asMap().entries.map((e) {
            return Container(
              margin: EdgeInsets.only(bottom: height * 0.005),
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03, vertical: height * 0.008),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: width * 0.04),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(fontSize: width * 0.032),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.red,
                    onPressed: () => onRemove(e.key),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.04,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
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
        fillColor: Colors.white,
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