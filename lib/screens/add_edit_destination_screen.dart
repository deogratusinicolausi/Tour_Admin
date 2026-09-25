import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/destination_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';


class AddEditDestinationScreen extends StatefulWidget {
  final DestinationModel? destination;

  const AddEditDestinationScreen({super.key, this.destination});

  @override
  State<AddEditDestinationScreen> createState() =>
      _AddEditDestinationScreenState();
}

class _AddEditDestinationScreenState extends State<AddEditDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Controllers
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // State
  String _imageUrl = '';
  List<String> _gallery = [];
  String _videoUrl = '';
  List<String> _videos = [];
  bool _isUploadingVideo = false;
  bool _featured = false;
  String _status = 'active';
  bool _isLoading = false;
  bool _isUploading = false;

  bool get isEditing => widget.destination != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadDestination();
    }
  }

  void _loadDestination() {
    final dest = widget.destination!;
    _nameController.text = dest.name;
    _countryController.text = dest.country;
    _regionController.text = dest.region;
    _descriptionController.text = dest.description;
    _locationController.text = dest.location;
    _latitudeController.text = dest.latitude.toString();
    _longitudeController.text = dest.longitude.toString();
    _imageUrl = dest.imageUrl;
    _gallery = List.from(dest.gallery);
    _featured = dest.featured;
    _status = dest.status;
    _videoUrl = dest.videoUrl;
    _videos = List.from(dest.videos);
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
          folder: 'turiva/destinations',
        );
      } else {
        url = await _cloudinaryService.uploadImage(
          File(pickedFile.path),
          folder: 'turiva/destinations',
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
          SnackBar(
            content: Text(context.tr('image_uploaded')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('upload_failed')),
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
  Future<void> _pickAndUploadVideo({bool isMain = true}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (pickedFile == null) return;
      setState(() => _isUploadingVideo = true);

      String? url;
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinaryService.uploadVideoBytes(bytes, folder: 'turiva/destinations/videos');
      } else {
        url = await _cloudinaryService.uploadVideo(File(pickedFile.path), folder: 'turiva/destinations/videos');
      }

      if (url != null) {
        setState(() {
          if (isMain) {
            _videoUrl = url!;
          } else {
            _videos.add(url!);
          }
          _isUploadingVideo = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isUploadingVideo = false);
      }
    } catch (e) {
      setState(() => _isUploadingVideo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('upload_main_image_error')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final destination = DestinationModel(
      id: widget.destination?.id ?? '',
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
      region: _regionController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      latitude: double.tryParse(_latitudeController.text) ?? 0.0,
      longitude: double.tryParse(_longitudeController.text) ?? 0.0,
      imageUrl: _imageUrl,
      gallery: _gallery,
      featured: _featured,
      status: _status,
      videoUrl: _videoUrl,
      videos: _videos,
      createdAt: widget.destination?.createdAt ?? DateTime.now(),
    );

    bool success;
    if (isEditing) {
      success = await _firestoreService.updateDestination(destination);
    } else {
      final id = await _firestoreService.addDestination(destination);
      success = id != null;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? context.tr('destination_updated')
                : context.tr('destination_added')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('failed_to_save')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? '✏️ ${context.tr('edit_destination')}' : '➕ ${context.tr('add_destination')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(15),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== MAIN IMAGE =====
              _buildSectionTitle('📸 ${context.tr('main_image')}', width, context),
              SizedBox(height: height * 0.01),
              GestureDetector(
                onTap: _isUploading ? null : () => _pickAndUploadImage(isMain: true),
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
                      style: _imageUrl.isEmpty
                          ? BorderStyle.solid
                          : BorderStyle.solid,
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
                        context.tr('tap_to_upload'),
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ],
                  )
                      : null,
                ),
              ),
              SizedBox(height: height * 0.025),

              // ===== GALLERY =====
              _buildSectionTitle('🖼️ ${context.tr('gallery_optional')}', width, context),
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
                          child: Icon(
                            Icons.add,
                            color: Colors.grey.shade400,
                            size: width * 0.08,
                          ),
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
                            onTap: () {
                              setState(() => _gallery.removeAt(index));
                            },
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

              // 🎬 VIDEO SECTION
              _buildSectionTitle('🎬 Video (Optional)', width, context),
              SizedBox(height: height * 0.01),

              GestureDetector(
                onTap: _isUploadingVideo ? null : () => _pickAndUploadVideo(isMain: true),
                child: Container(
                  height: height * 0.2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _videoUrl.isEmpty ? Colors.grey.shade300 : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: _isUploadingVideo
                      ? const Center(child: CircularProgressIndicator())
                      : _videoUrl.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_call,
                                    size: width * 0.15, color: Colors.grey.shade400),
                                SizedBox(height: height * 0.01),
                                Text('Tap to upload video',
                                    style: TextStyle(color: context.textSecondary)),
                              ],
                            )
                          : Stack(
                              children: [
                                Center(
                                  child: Icon(Icons.play_circle_fill,
                                      size: width * 0.2, color: AppColors.primary),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _videoUrl = ''),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              SizedBox(height: height * 0.025),

              // ===== BASIC INFO =====
              _buildSectionTitle('📝 ${context.tr('basic_info')}', width, context),
              SizedBox(height: height * 0.01),

              _buildTextField(
                controller: _nameController,
                label: context.tr('name'),
                icon: Icons.place,
                validator: (v) => v!.isEmpty ? context.tr('name_required') : null,
                context: context,
              ),
              SizedBox(height: height * 0.015),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _countryController,
                      label: context.tr('country'),
                      icon: Icons.flag,
                      validator: (v) => v!.isEmpty ? context.tr('country_required') : null,
                      context: context,
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildTextField(
                      controller: _regionController,
                      label: context.tr('region'),
                      icon: Icons.map,
                      context: context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),

              _buildTextField(
                controller: _locationController,
                label: context.tr('location'),
                icon: Icons.location_on,
                context: context,
              ),
              SizedBox(height: height * 0.015),

              _buildTextField(
                controller: _descriptionController,
                label: context.tr('description'),
                icon: Icons.description,
                maxLines: 4,
                context: context,
              ),
              SizedBox(height: height * 0.025),

              // ===== COORDINATES =====
              _buildSectionTitle('📍 ${context.tr('gps_coordinates')}', width, context),
              SizedBox(height: height * 0.01),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latitudeController,
                      label: context.tr('latitude'),
                      icon: Icons.my_location,
                      keyboardType: TextInputType.number,
                      context: context,
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: _buildTextField(
                      controller: _longitudeController,
                      label: context.tr('longitude'),
                      icon: Icons.my_location,
                      keyboardType: TextInputType.number,
                      context: context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.025),

              // ===== SETTINGS =====
              _buildSectionTitle('⚙️ ${context.tr('settings')}', width, context),
              SizedBox(height: height * 0.01),

              // Featured
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    '⭐ ${context.tr('featured')}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(context.tr('show_on_homepage')),
                  value: _featured,
                  activeColor: AppColors.accentGold,
                  onChanged: (v) => setState(() => _featured = v),
                ),
              ),
              SizedBox(height: height * 0.015),

              // Status
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('status'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                                    : context.textSecondary,
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

              // ===== SAVE BUTTON =====
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
                    isEditing ? context.tr('update_destination').toUpperCase() : context.tr('add_destination').toUpperCase(),
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

  Widget _buildSectionTitle(String title, double width, BuildContext context) {
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
    required BuildContext context,
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