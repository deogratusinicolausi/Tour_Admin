import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/beach_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';

class AddEditBeachScreen extends StatefulWidget {
  final BeachModel? beach;

  const AddEditBeachScreen({super.key, this.beach});

  @override
  State<AddEditBeachScreen> createState() => _AddEditBeachScreenState();
}

class _AddEditBeachScreenState extends State<AddEditBeachScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _cloudinary = CloudinaryService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String _country = 'Tanzania';
  String _waterType = 'Ocean';
  String _bestTime = 'All Year';
  String _imageUrl = '';
  List<String> _gallery = [];
  List<String> _activities = [];
  double _rating = 0.0;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  final List<String> _activityOptions = [
    '🏊 Swimming',
    '🏄 Surfing',
    '🤿 Snorkeling',
    '🛶 Kayaking',
    '⛵ Sailing',
    '🐠 Diving',
    '🌅 Sunset',
    '🍹 Beach Bar',
    '🏐 Volleyball',
    '🚤 Boat Tours',
  ];

  bool get isEditing => widget.beach != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _load();
  }

  void _load() {
    final b = widget.beach!;
    _nameController.text = b.name;
    _descriptionController.text = b.description;
    _locationController.text = b.location;
    _destinationController.text = b.destinationName;
    _latitudeController.text = b.latitude.toString();
    _longitudeController.text = b.longitude.toString();
    _country = b.country;
    _waterType = b.waterType;
    _bestTime = b.bestTime;
    _imageUrl = b.imageUrl;
    _gallery = List.from(b.gallery);
    _activities = List.from(b.activities);
    _rating = b.rating;
    _featured = b.featured;
    _status = b.status;
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
            folder: 'turiva/beaches');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/beaches');
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

    final beach = BeachModel(
      id: widget.beach?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      destinationName: _destinationController.text.trim(),
      country: _country,
      waterType: _waterType,
      bestTime: _bestTime,
      imageUrl: _imageUrl,
      gallery: _gallery,
      activities: _activities,
      rating: _rating,
      featured: _featured,
      status: _status,
      latitude: double.tryParse(_latitudeController.text) ?? 0.0,
      longitude: double.tryParse(_longitudeController.text) ?? 0.0,
      createdAt: widget.beach?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _service.updateBeach(beach);
    } else {
      final id = await _service.addBeach(beach);
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
    _destinationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? '✏️ Edit Beach' : '➕ Add Beach'),
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
                    color: Colors.white,
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
                              color: Colors.grey.shade600)),
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
                            color: Colors.white,
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
              _buildField(_nameController, 'Beach Name', Icons.beach_access,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(_locationController, 'Location', Icons.location_on),
              SizedBox(height: height * 0.015),
              _buildField(_destinationController, 'Nearby Destination',
                  Icons.place_outlined,
                  hint: 'e.g. Zanzibar, Dar es Salaam'),
              SizedBox(height: height * 0.015),
              _buildField(_descriptionController, 'Description',
                  Icons.description,
                  maxLines: 4),
              SizedBox(height: height * 0.025),

              _sectionTitle('🌊 Beach Details', width),
              SizedBox(height: height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown('Water Type', _waterType,
                        ['Ocean', 'Sea', 'Lake', 'River', 'Lagoon'], (v) {
                          setState(() => _waterType = v!);
                        }),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildDropdown('Best Time', _bestTime,
                        ['All Year', 'Dry Season', 'Wet Season', 'June-Oct'],
                            (v) {
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

              _sectionTitle('🏄 Activities', width),
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
                  children: _activityOptions.map((activity) {
                    final isSelected = _activities.contains(activity);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _activities.remove(activity);
                          } else {
                            _activities.add(activity);
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
                        child: Text(
                          activity,
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
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: height * 0.025),

              _sectionTitle('⭐ Rating', width),
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

              _sectionTitle('⚙️ Settings', width),
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
                    isEditing ? 'UPDATE BEACH' : 'ADD BEACH',
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
        color: Colors.grey.shade800,
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

  Widget _buildDropdown(
      String label,
      String value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
}