import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/mountain_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';

class AddEditMountainScreen extends StatefulWidget {
  final MountainModel? mountain;

  const AddEditMountainScreen({super.key, this.mountain});

  @override
  State<AddEditMountainScreen> createState() =>
      _AddEditMountainScreenState();
}

class _AddEditMountainScreenState extends State<AddEditMountainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _cloudinary = CloudinaryService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _heightController = TextEditingController();
  final _durationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _routeController = TextEditingController();
  final _includedController = TextEditingController();
  final _excludedController = TextEditingController();
  final _highlightController = TextEditingController();

  String _country = 'Tanzania';
  String _difficulty = 'Moderate';
  String _bestTime = 'All Year';
  String _imageUrl = '';
  List<String> _gallery = [];
  List<String> _routes = [];
  List<String> _included = [];
  List<String> _excluded = [];
  List<String> _highlights = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  final List<String> _difficulties = [
    'Easy',
    'Moderate',
    'Hard',
    'Extreme',
  ];

  final List<String> _bestTimeOptions = [
    'All Year',
    'Dry Season',
    'Wet Season',
    'June-October',
    'December-March',
    'January-February',
  ];

  bool get isEditing => widget.mountain != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _load();
  }

  void _load() {
    final m = widget.mountain!;
    _nameController.text = m.name;
    _descriptionController.text = m.description;
    _locationController.text = m.location;
    _heightController.text = m.height.toString();
    _durationController.text = m.duration;
    _latitudeController.text = m.latitude.toString();
    _longitudeController.text = m.longitude.toString();
    _country = m.country;
    _difficulty = m.difficulty;
    _bestTime = m.bestTime;
    _imageUrl = m.imageUrl;
    _gallery = List.from(m.gallery);
    _routes = List.from(m.routes);
    _included = List.from(m.included);
    _excluded = List.from(m.excluded);
    _highlights = List.from(m.highlights);
    _rating = m.rating;
    _featured = m.featured;
    _status = m.status;
  }

  Future<void> _pickImage({bool isMain = true}) async {
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
        url = await _cloudinary.uploadImageBytes(bytes,
            folder: 'turiva/mountains');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/mountains');
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
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload main image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final mountain = MountainModel(
      id: widget.mountain?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      country: _country,
      imageUrl: _imageUrl,
      gallery: _gallery,
      height: double.tryParse(_heightController.text) ?? 0.0,
      difficulty: _difficulty,
      duration: _durationController.text.trim(),
      bestTime: _bestTime,
      routes: _routes,
      included: _included,
      excluded: _excluded,
      highlights: _highlights,
      rating: _rating,
      featured: _featured,
      status: _status,
      latitude: double.tryParse(_latitudeController.text) ?? 0.0,
      longitude: double.tryParse(_longitudeController.text) ?? 0.0,
      createdAt: widget.mountain?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _service.updateMountain(mountain);
    } else {
      final id = await _service.addMountain(mountain);
      success = id != null;
    }

    setState(() => _isLoading = false);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '✅ Updated!' : '✅ Added!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _durationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _routeController.dispose();
    _includedController.dispose();
    _excludedController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? context.tr('edit_mountain') : context.tr('add_mountain')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('📸 Main Image', width),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap: _isUploading
                    ? null
                    : () => _pickImage(isMain: true),
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
                      Text('Tap to upload',
                          style: TextStyle(
                              color: context.textSecondary)),
                    ],
                  )
                      : null,
                ),
              ),
              SizedBox(height: height * 0.02),

              _sectionTitle('🖼️ Gallery', width),
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
                            : () => _pickImage(isMain: false),
                        child: Container(
                          width: height * 0.12,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border:
                            Border.all(color: Colors.grey.shade300),
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
                            onTap: () => setState(
                                    () => _gallery.removeAt(index)),
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

              _sectionTitle('📝 Basic Information', width),
              SizedBox(height: height * 0.01),
              _buildField(_nameController, 'Mountain Name', Icons.terrain,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(_locationController, 'Location', Icons.location_on),
              SizedBox(height: height * 0.015),
              _buildField(_descriptionController, 'Description',
                  Icons.description,
                  maxLines: 4),
              SizedBox(height: height * 0.025),

              _sectionTitle('⛰️ Mountain Details', width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                        _heightController, 'Height (m)', Icons.height,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildField(
                        _durationController, 'Duration', Icons.access_time,
                        hint: '5-7 days'),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown('Difficulty', _difficulty,
                        _difficulties, (v) {
                          setState(() => _difficulty = v!);
                        }),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildDropdown('Best Time', _bestTime,
                        _bestTimeOptions, (v) {
                          setState(() => _bestTime = v!);
                        }),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                        _latitudeController, 'Latitude', Icons.my_location,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildField(
                        _longitudeController, 'Longitude', Icons.my_location,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // ROUTES
              _sectionTitle('🗺️ Routes', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _routeController,
                items: _routes,
                hint: 'e.g. Marangu, Machame',
                icon: Icons.route,
                onAdd: () => _addToList(_routeController, _routes),
                onRemove: (i) => setState(() => _routes.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // HIGHLIGHTS
              _sectionTitle('✨ Highlights', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _highlightController,
                items: _highlights,
                hint: 'e.g. Uhuru Peak, Glaciers',
                icon: Icons.star,
                color: AppColors.accentGold,
                onAdd: () => _addToList(_highlightController, _highlights),
                onRemove: (i) => setState(() => _highlights.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // INCLUDED
              _sectionTitle('✅ What\'s Included', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _includedController,
                items: _included,
                hint: 'e.g. Guide, Porters, Meals',
                icon: Icons.check_circle,
                color: Colors.green,
                onAdd: () => _addToList(_includedController, _included),
                onRemove: (i) => setState(() => _included.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // EXCLUDED
              _sectionTitle('❌ Not Included', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _excludedController,
                items: _excluded,
                hint: 'e.g. Flights, Insurance',
                icon: Icons.cancel,
                color: Colors.red,
                onAdd: () => _addToList(_excludedController, _excluded),
                onRemove: (i) => setState(() => _excluded.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // RATING
              _sectionTitle('⭐ Rating', width),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
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
              _sectionTitle('⚙️ Settings', width),
              SizedBox(height: height * 0.01),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
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
                  color: context.cardBg,
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
              ),
              SizedBox(height: height * 0.03),

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
                    isEditing ? 'UPDATE MOUNTAIN' : 'ADD MOUNTAIN',
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

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.04,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
        String? hint,
      }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _buildDropdown(
      String label,
      String value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
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
                  fillColor: context.cardBg,
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
                color: context.cardBg,
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
}