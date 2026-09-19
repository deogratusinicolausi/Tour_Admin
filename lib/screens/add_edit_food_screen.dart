import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/food_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../providers/app_theme_provider.dart';
import 'package:provider/provider.dart';

class AddEditFoodScreen extends StatefulWidget {
  final FoodModel? food;

  const AddEditFoodScreen({super.key, this.food});

  @override
  State<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _cloudinary = CloudinaryService();
  final _nameController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _regionController = TextEditingController();
  final _priceController = TextEditingController();
  final _restaurantController = TextEditingController();
  final _contactController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _preparationController = TextEditingController();
  final _pairingController = TextEditingController();

  String _category = 'Dish';
  String _country = 'Tanzania';
  String _currency = 'USD';
  String _spiceLevel = 'Mild';
  String _servingTime = 'Lunch';
  String _imageUrl = '';
  List<String> _gallery = [];
  List<String> _ingredients = [];
  List<String> _preparation = [];
  List<String> _dietary = [];
  List<String> _bestPairings = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'Dish', 'label': '🍛 Dish'},
    {'value': 'Cuisine', 'label': '🥘 Cuisine'},
    {'value': 'Restaurant', 'label': '🏨 Restaurant'},
    {'value': 'Drink', 'label': '🍹 Drink'},
    {'value': 'Dessert', 'label': '🎂 Dessert'},
    {'value': 'Street Food', 'label': '🍢 Street Food'},
  ];

  final List<String> _spiceLevels = ['Mild', 'Medium', 'Hot', 'Very Hot'];
  final List<String> _servingTimes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'All Day',
  ];
  final List<Map<String, String>> _dietaryOptions = [
    {'value': 'Vegetarian', 'label': '🥗 Vegetarian'},
    {'value': 'Vegan', 'label': '🌱 Vegan'},
    {'value': 'Halal', 'label': '☪️ Halal'},
    {'value': 'Gluten-Free', 'label': '🌾 Gluten-Free'},
    {'value': 'Dairy-Free', 'label': '🥛 Dairy-Free'},
    {'value': 'Nut-Free', 'label': '🥜 Nut-Free'},
  ];

  bool get isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _load();
  }

  void _load() {
    final f = widget.food!;
    _nameController.text = f.name;
    _subCategoryController.text = f.subCategory;
    _descriptionController.text = f.description;
    _locationController.text = f.location;
    _regionController.text = f.region;
    _priceController.text = f.price.toString();
    _restaurantController.text = f.restaurantName;
    _contactController.text = f.contactInfo;
    _latitudeController.text = f.latitude.toString();
    _longitudeController.text = f.longitude.toString();
    _category = f.category;
    _country = f.country;
    _currency = f.currency;
    _spiceLevel = f.spiceLevel;
    _servingTime = f.servingTime;
    _imageUrl = f.imageUrl;
    _gallery = List.from(f.gallery);
    _ingredients = List.from(f.ingredients);
    _preparation = List.from(f.preparation);
    _dietary = List.from(f.dietary);
    _bestPairings = List.from(f.bestPairings);
    _rating = f.rating;
    _featured = f.featured;
    _status = f.status;
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
            folder: 'turiva/food');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/food');
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
        SnackBar(
          content: Text(context.tr('please_upload_image')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final food = FoodModel(
      id: widget.food?.id ?? '',
      name: _nameController.text.trim(),
      category: _category,
      subCategory: _subCategoryController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      region: _regionController.text.trim(),
      country: _country,
      imageUrl: _imageUrl,
      gallery: _gallery,
      ingredients: _ingredients,
      preparation: _preparation,
      spiceLevel: _spiceLevel,
      dietary: _dietary,
      price: double.tryParse(_priceController.text) ?? 0.0,
      currency: _currency,
      servingTime: _servingTime,
      restaurantName: _restaurantController.text.trim(),
      contactInfo: _contactController.text.trim(),
      bestPairings: _bestPairings,
      rating: _rating,
      featured: _featured,
      status: _status,
      latitude: double.tryParse(_latitudeController.text) ?? 0.0,
      longitude: double.tryParse(_longitudeController.text) ?? 0.0,
      createdAt: widget.food?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _service.updateFood(food);
    } else {
      final id = await _service.addFood(food);
      success = id != null;
    }

    setState(() => _isLoading = false);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '✅ ${context.tr('updated')}' : '✅ ${context.tr('added')}'),
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
    _priceController.dispose();
    _restaurantController.dispose();
    _contactController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ingredientController.dispose();
    _preparationController.dispose();
    _pairingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? '✏️ ${context.tr('edit_food')}' : '➕ ${context.tr('add_food')}'),
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
              _sectionTitle('📸 ${context.tr('main_image')}', width, context),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap:
                _isUploading ? null : () => _pickImage(isMain: true),
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
                          color: context.textSecondary),
                      SizedBox(height: height * 0.01),
                      Text(context.tr('tap_to_upload'),
                          style: TextStyle(
                              color: context.textSecondary)),
                    ],
                  )
                      : null,
                ),
              ),
              SizedBox(height: height * 0.02),

              _sectionTitle('🖼️ ${context.tr('gallery')}', width, context),
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
                            border: Border.all(
                              color: context.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(Icons.add,
                              color: context.textSecondary,
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
              _sectionTitle('🍽️ ${context.tr('category')}', width, context),
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
                              : context.textSecondary.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary,
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
              _sectionTitle('📝 ${context.tr('basic_info')}', width, context),
              SizedBox(height: height * 0.01),
              _buildField(context, _nameController, context.tr('name'), Icons.restaurant,
                  validator: (v) => v!.isEmpty ? context.tr('required') : null),
              SizedBox(height: height * 0.015),
              _buildField(context, _subCategoryController, context.tr('sub_category'),
                  Icons.category,
                  hint: 'e.g. Swahili, Maasai'),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildField(context,
                        _locationController, context.tr('location'), Icons.location_on),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildField(context,
                        _regionController, context.tr('region'), Icons.map),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              _buildField(context, _descriptionController, context.tr('description'),
                  Icons.description,
                  maxLines: 4),
              SizedBox(height: height * 0.025),

              // DETAILS
              _sectionTitle('ℹ️ ${context.tr('details')}', width, context),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildField(context,
                        _priceController, context.tr('price'), Icons.attach_money,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildDropdown(context, context.tr('serving_time'), _servingTime,
                        _servingTimes, (v) {
                          setState(() => _servingTime = v!);
                        }),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              _buildDropdown(context, context.tr('spice_level'), _spiceLevel, _spiceLevels, (v) {
                setState(() => _spiceLevel = v!);
              }),
              SizedBox(height: height * 0.015),
              _buildField(context, _restaurantController, context.tr('restaurant_name'),
                  Icons.store),
              SizedBox(height: height * 0.015),
              _buildField(context,
                  _contactController, context.tr('contact_info'), Icons.contact_phone,
                  hint: 'Phone, email'),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildField(context,
                        _latitudeController, context.tr('latitude'), Icons.my_location,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildField(context,
                        _longitudeController, context.tr('longitude'),
                        Icons.my_location,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // DIETARY
              _sectionTitle('🥗 ${context.tr('dietary_options')}', width, context),
              SizedBox(height: height * 0.01),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietaryOptions.map((diet) {
                  final isSelected =
                  _dietary.contains(diet['value']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _dietary.remove(diet['value']);
                        } else {
                          _dietary.add(diet['value']!);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green
                            : context.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : context.textSecondary.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        diet['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: height * 0.025),

              // INGREDIENTS
              _sectionTitle('🥘 ${context.tr('ingredients')}', width, context),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                context: context,
                controller: _ingredientController,
                items: _ingredients,
                hint: 'e.g. Rice, Coconut milk',
                icon: Icons.shopping_basket,
                color: Colors.orange,
                onAdd: () => _addToList(_ingredientController, _ingredients),
                onRemove: (i) => setState(() => _ingredients.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // PREPARATION
              _sectionTitle('👨‍🍳 ${context.tr('preparation_steps')}', width, context),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                context: context,
                controller: _preparationController,
                items: _preparation,
                hint: 'e.g. Boil water, Add rice',
                icon: Icons.kitchen,
                color: Colors.brown,
                onAdd: () =>
                    _addToList(_preparationController, _preparation),
                onRemove: (i) =>
                    setState(() => _preparation.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // BEST PAIRINGS
              _sectionTitle('🍷 ${context.tr('best_pairings')}', width, context),
              SizedBox(height: height * 0.01),
              _buildListBuilder(
                context: context,
                controller: _pairingController,
                items: _bestPairings,
                hint: 'e.g. Fresh juice, Kachumbari',
                icon: Icons.local_dining,
                color: Colors.purple,
                onAdd: () =>
                    _addToList(_pairingController, _bestPairings),
                onRemove: (i) =>
                    setState(() => _bestPairings.removeAt(i)),
                width: width,
                height: height,
              ),
              SizedBox(height: height * 0.025),

              // RATING
              _sectionTitle('⭐ ${context.tr('rating')}', width, context),
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
              _sectionTitle('⚙️ ${context.tr('settings')}', width, context),
              SizedBox(height: height * 0.01),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text('⭐ ${context.tr('featured')}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
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
                              : context.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.textPrimary,
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
                    isEditing ? context.tr('update_food').toUpperCase() : context.tr('add_food').toUpperCase(),
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

  Widget _sectionTitle(String title, double width, BuildContext context) {
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
      BuildContext context,
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
        prefixIcon: Icon(icon, color: context.textSecondary),
        filled: true,
        fillColor: context.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.textSecondary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      BuildContext context,
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
        border: Border.all(
          color: context.textSecondary.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: TextStyle(color: context.textPrimary)),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: TextStyle(
                            color: context.textPrimary)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildListBuilder({
    required BuildContext context,
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
                      style: TextStyle(fontSize: width * 0.032, color: context.textPrimary),
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