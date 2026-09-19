import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/culture_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';


class AddEditCultureScreen extends StatefulWidget {
  final CultureModel? culture;

  const AddEditCultureScreen({super.key, this.culture});

  @override
  State<AddEditCultureScreen> createState() =>
      _AddEditCultureScreenState();
}

class _AddEditCultureScreenState extends State<AddEditCultureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _cloudinary = CloudinaryService();

  final _nameController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _regionController = TextEditingController();
  final _durationController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _contactController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _highlightController = TextEditingController();
  final _languageController = TextEditingController();
  final _activityController = TextEditingController();

  String _category = 'Tribe';
  String _country = 'Tanzania';
  String _currency = 'USD';
  String _imageUrl = '';
  List<String> _gallery = [];
  List<String> _highlights = [];
  List<String> _languages = [];
  List<String> _activities = [];
  List<String> _bestTimeToVisit = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'Tribe', 'label': '👥 Tribe'},
    {'value': 'Festival', 'label': '🎉 Festival'},
    {'value': 'Art', 'label': '🎨 Art'},
    {'value': 'Music', 'label': '🎵 Music'},
    {'value': 'Dance', 'label': '💃 Dance'},
    {'value': 'Food', 'label': '🍛 Food'},
    {'value': 'Historical', 'label': '🏛️ Historical'},
    {'value': 'Village', 'label': '🏠 Village'},
    {'value': 'Craft', 'label': '🧵 Craft'},
  ];

  final List<String> _bestTimeOptions = [
    'All Year',
    'Dry Season',
    'Wet Season',
    'June-October',
    'December-March',
    'Festival Time',
  ];

  bool get isEditing => widget.culture != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _load();
  }

  void _load() {
    final c = widget.culture!;
    _nameController.text = c.name;
    _subCategoryController.text = c.subCategory;
    _descriptionController.text = c.description;
    _locationController.text = c.location;
    _regionController.text = c.region;
    _durationController.text = c.duration;
    _entryFeeController.text = c.entryFee.toString();
    _contactController.text = c.contactInfo;
    _latitudeController.text = c.latitude.toString();
    _longitudeController.text = c.longitude.toString();
    _category = c.category;
    _country = c.country;
    _currency = c.currency;
    _imageUrl = c.imageUrl;
    _gallery = List.from(c.gallery);
    _highlights = List.from(c.highlights);
    _languages = List.from(c.languages);
    _activities = List.from(c.activities);
    _bestTimeToVisit = List.from(c.bestTimeToVisit);
    _rating = c.rating;
    _featured = c.featured;
    _status = c.status;
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
            folder: 'turiva/culture');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/culture');
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

    final culture = CultureModel(
      id: widget.culture?.id ?? '',
      name: _nameController.text.trim(),
      category: _category,
      subCategory: _subCategoryController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      region: _regionController.text.trim(),
      country: _country,
      imageUrl: _imageUrl,
      gallery: _gallery,
      highlights: _highlights,
      bestTimeToVisit: _bestTimeToVisit,
      duration: _durationController.text.trim(),
      entryFee: double.tryParse(_entryFeeController.text) ?? 0.0,
      currency: _currency,
      contactInfo: _contactController.text.trim(),
      languages: _languages,
      activities: _activities,
      rating: _rating,
      featured: _featured,
      status: _status,
      latitude: double.tryParse(_latitudeController.text) ?? 0.0,
      longitude: double.tryParse(_longitudeController.text) ?? 0.0,
      createdAt: widget.culture?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _service.updateCulture(culture);
    } else {
      final id = await _service.addCulture(culture);
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
    _subCategoryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _regionController.dispose();
    _durationController.dispose();
    _entryFeeController.dispose();
    _contactController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _highlightController.dispose();
    _languageController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? context.tr('edit_culture') : context.tr('add_culture')),
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

              // GALLERY
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

              // CATEGORY
              _sectionTitle('🎭 Category', width),
              SizedBox(height: height * 0.01),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat['value'];
                  return GestureDetector(
                    onTap: () => setState(
                            () => _category = cat['value'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: height * 0.025),

              // BASIC INFO
              _sectionTitle('📝 Basic Information', width),
              SizedBox(height: height * 0.01),
              _buildField(_nameController, 'Name', Icons.museum,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(
                  _subCategoryController, 'Sub Category', Icons.category,
                  hint: 'e.g. Maasai, Tingatinga'),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                        _locationController, 'Location', Icons.location_on),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildField(
                        _regionController, 'Region', Icons.map),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              _buildField(_descriptionController, 'Description',
                  Icons.description,
                  maxLines: 4),
              SizedBox(height: height * 0.025),

              // DETAILS
              _sectionTitle('ℹ️ Details', width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                        _durationController, 'Duration', Icons.access_time,
                        hint: 'e.g. 2 hours, 3 days'),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildField(
                        _entryFeeController, 'Entry Fee', Icons.attach_money,
                        keyboardType: TextInputType.number),
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
              SizedBox(height: height * 0.015),
              _buildField(
                  _contactController, 'Contact Info', Icons.contact_phone,
                  hint: 'Phone, email, or website'),
              SizedBox(height: height * 0.025),

              // HIGHLIGHTS
              _sectionTitle('✨ Highlights', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _highlightController,
                items: _highlights,
                hint: 'e.g. Traditional dance, Beadwork',
                icon: Icons.star,
                color: AppColors.accentGold,
                onAdd: () => _addToList(_highlightController, _highlights),
                onRemove: (i) => setState(() => _highlights.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // LANGUAGES
              _sectionTitle('🗣️ Languages', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _languageController,
                items: _languages,
                hint: 'e.g. Swahili, Maa, Chagga',
                icon: Icons.language,
                color: Colors.blue,
                onAdd: () => _addToList(_languageController, _languages),
                onRemove: (i) => setState(() => _languages.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // ACTIVITIES
              _sectionTitle('🎯 Activities', width),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                controller: _activityController,
                items: _activities,
                hint: 'e.g. Village tour, Dance performance',
                icon: Icons.celebration,
                color: Colors.purple,
                onAdd: () => _addToList(_activityController, _activities),
                onRemove: (i) => setState(() => _activities.removeAt(i)),
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
                  title: Text(context.tr('featured'),
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
                    isEditing ? context.tr('update_culture') : context.tr('add_culture'),
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