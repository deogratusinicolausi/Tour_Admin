import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';



class AddEditActivityScreen extends StatefulWidget {
  final ActivityModel? activity;
  const AddEditActivityScreen({super.key, this.activity});

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _cloudinaryService = CloudinaryService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  String _currency = 'USD';
  String _destinationId = '';
  String _destinationName = '';
  String _activityType = 'Adventure';
  String _imageUrl = '';
  List<String> _gallery = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  List<Map<String, dynamic>> _destinations = [];

  final List<Map<String, String>> _types = [
    {'icon': '🚶', 'name': 'Walking'},
    {'icon': '🥾', 'name': 'Hiking'},
    {'icon': '🚴', 'name': 'Cycling'},
    {'icon': '🏊', 'name': 'Water Sports'},
    {'icon': '🪂', 'name': 'Adventure'},
    {'icon': '🎭', 'name': 'Cultural'},
    {'icon': '🍳', 'name': 'Cooking'},
    {'icon': '📸', 'name': 'Photography'},
    {'icon': '🎈', 'name': 'Balloon Safari'},
  ];

  bool get isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    if (isEditing) _load();
  }

  void _load() {
    final a = widget.activity!;
    _nameController.text = a.name;
    _descriptionController.text = a.description;
    _priceController.text = a.price.toString();
    _durationController.text = a.duration;
    _currency = a.currency;
    _destinationId = a.destinationId;
    _destinationName = a.destinationName;
    _activityType = a.activityType;
    _imageUrl = a.imageUrl;
    _gallery = List.from(a.gallery);
    _rating = a.rating;
    _featured = a.featured;
    _status = a.status;
  }

  Future<void> _loadDestinations() async {
    final list = await _firestoreService.getDestinationsForDropdown();
    if (mounted) setState(() => _destinations = list);
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
        url = await _cloudinaryService.uploadImageBytes(bytes, folder: 'turiva/activities');
      } else {
        url = await _cloudinaryService.uploadImage(File(pickedFile.path), folder: 'turiva/activities');
      }

      if (url != null) {
        setState(() {
          if (isMain) _imageUrl = url!;
          else _gallery.add(url!);
          _isUploading = false;
        });
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_upload_main_image')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final activity = ActivityModel(
      id: widget.activity?.id ?? '',
      name: _nameController.text.trim(),
      destinationId: _destinationId,
      destinationName: _destinationName,
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      currency: _currency,
      duration: _durationController.text.trim(),
      imageUrl: _imageUrl,
      gallery: _gallery,
      rating: _rating,
      status: _status,
      featured: _featured,
      activityType: _activityType,
      createdAt: widget.activity?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) success = await _firestoreService.updateActivity(activity);
    else {
      final id = await _firestoreService.addActivity(activity);
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
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? '✏️ ${context.tr('edit_activity')}' : '➕ ${context.tr('add_activity')}'),
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
              _buildTitle('📸 ${context.tr('main_image')}', width),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap: _isUploading ? null : () => _pickImage(isMain: true),
                child: Container(
                  height: height * 0.25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageUrl.isEmpty ? context.textSecondary.withOpacity(0.3) : AppColors.primary,
                      width: 2,
                    ),
                    image: _imageUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(_imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageUrl.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: width * 0.15, color: context.textSecondary),
                      SizedBox(height: height * 0.01),
                      Text(context.tr('tap_to_upload'),
                          style: TextStyle(color: context.textSecondary)),
                    ],
                  )
                      : null,
                ),
              ),
              SizedBox(height: height * 0.02),

              _buildTitle('🖼️ ${context.tr('gallery')}', width),
              SizedBox(height: height * 0.01),
              SizedBox(
                height: height * 0.12,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gallery.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _gallery.length) {
                      return GestureDetector(
                        onTap: _isUploading ? null : () => _pickImage(isMain: false),
                        child: Container(
                          width: height * 0.12,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.textSecondary.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.add,
                              color: context.textSecondary, size: width * 0.08),
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
                                fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _gallery.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
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

              _buildTitle('📝 ${context.tr('basic_information')}', width),
              SizedBox(height: height * 0.01),
              _buildField(_nameController, context.tr('activity_name'), Icons.celebration,
                  validator: (v) => v!.isEmpty ? context.tr('required') : null),
              SizedBox(height: height * 0.015),

              DropdownButtonFormField<String>(
                value: _destinationId.isEmpty ? null : _destinationId,
                decoration: InputDecoration(
                  labelText: context.tr('destination'),
                  prefixIcon: const Icon(Icons.place),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: _destinations.map((d) {
                  return DropdownMenuItem<String>(
                    value: d['id'] as String,
                    child: Text(d['name'] as String? ?? '', style: TextStyle(color: context.textPrimary)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    final d = _destinations.firstWhere((x) => x['id'] == v);
                    setState(() {
                      _destinationId = v;
                      _destinationName = d['name'] as String? ?? '';
                    });
                  }
                },
              ),
              SizedBox(height: height * 0.015),

              _buildField(_descriptionController, context.tr('description'), Icons.description,
                  maxLines: 4),
              SizedBox(height: height * 0.025),

              _buildTitle('🎯 ${context.tr('activity_type')}', width),
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
                  children: _types.map((t) {
                    final isSelected = _activityType == t['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _activityType = t['name']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : context.pageBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t['icon']!),
                            const SizedBox(width: 5),
                            Text(
                              context.tr(t['name']!.toLowerCase()),
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

              _buildTitle('💰 ${context.tr('pricing')}', width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildField(_priceController, context.tr('price'), Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? context.tr('required') : null),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03, vertical: height * 0.02),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.textSecondary.withOpacity(0.3)),
                      ),
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['USD', 'TZS', 'EUR', 'GBP']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.textPrimary))))
                            .toList(),
                        onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),

              _buildField(_durationController, context.tr('duration'), Icons.access_time,
                  hint: context.tr('duration_hint')),
              SizedBox(height: height * 0.025),

              _buildTitle('⭐ ${context.tr('rating')}', width),
              SizedBox(height: height * 0.01),
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                    color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating.floor() ? Icons.star : Icons.star_border,
                        color: AppColors.accentGold,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _rating = index + 1.0),
                    );
                  }),
                ),
              ),
              SizedBox(height: height * 0.025),

              _buildTitle('⚙️ ${context.tr('settings')}', width),
              SizedBox(height: height * 0.01),
              Container(
                decoration: BoxDecoration(
                    color: context.cardBg, borderRadius: BorderRadius.circular(12)),
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
                    color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: ['active', 'inactive'].map((s) {
                    final isSelected = _status == s;
                    return GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: Container(
                        margin: EdgeInsets.only(right: width * 0.03),
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05, vertical: height * 0.01),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (s == 'active' ? Colors.green : Colors.grey)
                              : context.pageBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr(s).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.textSecondary,
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
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isEditing ? context.tr('update_activity').toUpperCase() : context.tr('add_activity').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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

  Widget _buildTitle(String t, double w) => Text(
    t,
    style: TextStyle(
        fontSize: w * 0.04,
        fontWeight: FontWeight.bold,
        color: context.textPrimary),
  );

  Widget _buildField(
      TextEditingController c,
      String label,
      IconData icon, {
        String? Function(String?)? validator,
        int maxLines = 1,
        TextInputType? keyboardType,
        String? hint,
      }) {
    return TextFormField(
      controller: c,
      validator: validator,
      style: TextStyle(color: context.textPrimary),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.textSecondary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}