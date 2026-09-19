import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/admin_profile_service.dart';
import '../services/cloudinary_service.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';
import '../utils/colors.dart';
import 'admin_login_screen.dart';
import 'settings_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _service = AdminProfileService();
  final _cloudinary = CloudinaryService();
  final _user = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  String _photoUrl = '';
  String _email = '';
  String _role = 'admin';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final data = await _service.getAdminProfile();
    final stats = await _service.getAdminStats();

    if (mounted) {
      setState(() {
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _countryController.text = data['country'] ?? '';
          _cityController.text = data['city'] ?? '';
          _photoUrl = data['photoUrl'] ?? '';
          _email = data['email'] ?? '';
          _role = data['role'] ?? 'admin';
        } else {
          _email = _user?.email ?? '';
          _nameController.text = _user?.displayName ?? 'Admin';
          _photoUrl = _user?.photoURL ?? '';
        }
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() => _isUploading = true);

      String? url;
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinary.uploadImageBytes(bytes,
            folder: 'turiva/admin');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/admin');
      }

      if (url != null) {
        await _service.updatePhoto(url);
        setState(() => _photoUrl = url!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('photo_updated')),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError(context.tr('name_required'));
      return;
    }

    setState(() => _isSaving = true);

    final ok = await _service.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      country: _countryController.text.trim(),
      city: _cityController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('profile_updated')),
            backgroundColor: AppColors.primary,
          ),
        );
        await _user?.reload();
        _loadProfile();
      }
    } else {
      _showError(context.tr('update_failed'));
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('🔐 ${context.tr('change_password')}'),
        backgroundColor: context.cardBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: context.tr('current_password'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newController,
              obscureText: true,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: context.tr('new_password'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              obscureText: true,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                labelText: context.tr('confirm_password'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text(context.tr('change'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      if (newController.text != confirmController.text) {
        _showError(context.tr('password_mismatch'));
        return;
      }

      if (newController.text.length < 6) {
        _showError(context.tr('password_short'));
        return;
      }

      final success = await _service.changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('password_changed')),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        _showError(context.tr('change_failed'));
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('🚪 ${context.tr('logout')}?'),
        content: Text(context.tr('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('👤 ${context.tr('admin_profile')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          children: [
            // ⭐️ PROFILE HEADER
            _buildProfileHeader(width, height),

            SizedBox(height: height * 0.025),

            // ⭐️ STATS
            _buildStats(width, height),

            SizedBox(height: height * 0.025),

            // ⭐️ EDIT PROFILE
            _buildSectionTitle('✏️ ${context.tr('edit_profile')}', width),
            SizedBox(height: height * 0.015),
            _buildTextField(_nameController, context.tr('full_name'), Icons.person),
            SizedBox(height: height * 0.015),
            _buildTextField(_phoneController, context.tr('phone_number'), Icons.phone,
                keyboardType: TextInputType.phone),
            SizedBox(height: height * 0.015),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      _countryController, context.tr('country'), Icons.flag),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: _buildTextField(
                      _cityController, 'City', Icons.location_city),
                ),
              ],
            ),
            SizedBox(height: height * 0.015),
            _buildTextField(_bioController, context.tr('bio'), Icons.description,
                maxLines: 3),
            SizedBox(height: height * 0.02),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  context.tr('save_changes').toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: height * 0.03),

            // ⭐️ ACCOUNT SETTINGS
            _buildSectionTitle('⚙️ ${context.tr('account_settings')}', width),
            SizedBox(height: height * 0.015),
            _buildActionTile(
              icon: Icons.lock,
              title: context.tr('change_password'),
              subtitle: context.tr('update_password_hint'),
              color: Colors.blue,
              onTap: _changePassword,
              width: width,
            ),
            SizedBox(height: height * 0.01),
            _buildActionTile(
              icon: Icons.settings,
              title: context.tr('app_settings'),
              subtitle: context.tr('app_settings_hint'),
              color: AppColors.accentGold,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
              width: width,
            ),
            SizedBox(height: height * 0.01),
            _buildActionTile(
              icon: Icons.info,
              title: context.tr('about_turiva'),
              subtitle: '${context.tr('version')} 1.0.0',
              color: Colors.green,
              onTap: () => _showAbout(width),
              width: width,
            ),
            SizedBox(height: height * 0.01),
            _buildActionTile(
              icon: Icons.logout,
              title: context.tr('logout'),
              subtitle: context.tr('logout_hint'),
              color: Colors.red,
              onTap: _logout,
              width: width,
            ),

            SizedBox(height: height * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: width * 0.15,
                backgroundColor: Colors.white,
                backgroundImage:
                _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                child: _photoUrl.isEmpty
                    ? Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: width * 0.12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadImage,
                  child: Container(
                    padding: EdgeInsets.all(width * 0.025),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading
                        ? SizedBox(
                      width: width * 0.04,
                      height: width * 0.04,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : Icon(Icons.camera_alt,
                        color: Colors.white, size: width * 0.04),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'Admin',
            style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.06,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height * 0.005),
          Text(
            _email,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: width * 0.035),
          ),
          SizedBox(height: height * 0.015),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.008),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified,
                    color: AppColors.accentGold, size: 16),
                SizedBox(width: width * 0.015),
                Text(
                  _role.toUpperCase(),
                  style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.03),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(double width, double height) {
    return Row(
      children: [
        _statCard('📊', '${_stats['activities'] ?? 0}', context.tr('activities'), width),
        _statCard('✅', '${_stats['bookings'] ?? 0}', context.tr('confirmed'), width),
        _statCard('💬', '${_stats['replies'] ?? 0}', context.tr('replies'), width),
      ],
    );
  }

  Widget _statCard(
      String emoji, String value, String label, double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.01),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: context.cardBg,
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
            Text(emoji, style: TextStyle(fontSize: width * 0.06)),
            SizedBox(height: width * 0.01),
            Text(value,
                style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Text(label,
                style: TextStyle(
                    fontSize: width * 0.026, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double width) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.bold,
              color: context.textPrimary)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.textSecondary),
        filled: true,
        fillColor: context.cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.textSecondary.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: width * 0.05),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                          color: context.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: width * 0.028,
                          color: context.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: width * 0.035, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showAbout(double width) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Row(
          children: [
            const Icon(Icons.explore, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(context.tr('app_name'), style: TextStyle(color: context.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.tr('version')} 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Management portal for TURIVA Tourism Platform.\n\n'
                  '© 2025 TURIVA. All rights reserved.',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 15),
            Text('Made with ❤️ in Tanzania 🇹🇿',
                style: TextStyle(color: context.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('close'))),
        ],
      ),
    );
  }
}