import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../utils/colors.dart';
import 'admin_login_screen.dart';
import 'settings_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _cloudinary = CloudinaryService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  User? _user;
  Map<String, dynamic>? _userData;
  String _photoUrl = '';
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _user = _auth.currentUser;
    if (_user == null) return;

    try {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>;
        _nameController.text = _userData?['name'] ?? _user!.displayName ?? '';
        _phoneController.text = _userData?['phone'] ?? '';
        _bioController.text = _userData?['bio'] ?? '';
        _photoUrl = _userData?['photoUrl'] ?? _user!.photoURL ?? '';
      }
    } catch (e) {
      print('Error loading profile: $e');
    }

    if (mounted) setState(() => _isLoading = false);
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
        url = await _cloudinary.uploadImageBytes(bytes, folder: 'turiva/admin');
      } else {
        url = await _cloudinary.uploadImage(
            File(pickedFile.path), folder: 'turiva/admin');
      }

      if (url != null) {
        await _user!.updatePhotoURL(url);
        await _firestore.collection('users').doc(_user!.uid).update({
          'photoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _photoUrl = url!;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile photo updated!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    setState(() => _isLoading = true);

    try {
      await _user!.updateDisplayName(_nameController.text.trim());
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _user!.reload();
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _changePassword() async {
    final email = _user?.email;
    if (email == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password?'),
        content: Text('A password reset link will be sent to:\n\n$email'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send Link')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _auth.sendPasswordResetEmail(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📧 Reset link sent to $email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('👤 Admin Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          children: [
            // PROFILE HEADER
            _buildProfileHeader(width, height),

            SizedBox(height: height * 0.03),

            // STATS
            _buildStats(width, height),

            SizedBox(height: height * 0.03),

            // EDIT PROFILE
            _buildSectionTitle('✏️ Edit Profile', width),
            SizedBox(height: height * 0.015),
            _buildTextField(_nameController, 'Full Name', Icons.person),
            SizedBox(height: height * 0.015),
            _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                keyboardType: TextInputType.phone),
            SizedBox(height: height * 0.015),
            _buildTextField(_bioController, 'Bio', Icons.description,
                maxLines: 3),
            SizedBox(height: height * 0.02),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: height * 0.04),

            // ACTIONS
            _buildSectionTitle('⚙️ Account Settings', width),
            SizedBox(height: height * 0.015),
            _buildActionTile(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Send reset link to email',
              color: Colors.blue,
              onTap: _changePassword,
              width: width,
            ),
            SizedBox(height: height * 0.01),
            _buildActionTile(
              icon: Icons.settings,
              title: 'App Settings',
              subtitle: 'Notifications, theme, language',
              color: AppColors.accentGold,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              width: width,
            ),
            SizedBox(height: height * 0.01),
            _buildActionTile(
              icon: Icons.info,
              title: 'About TURIVA',
              subtitle: 'Version 1.0.0',
              color: Colors.green,
              onTap: () => _showAbout(width),
              width: width,
            ),
            SizedBox(height: height * 0.01),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of admin account',
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
            _nameController.text.isNotEmpty ? _nameController.text : 'Admin',
            style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.06,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height * 0.005),
          Text(
            _user?.email ?? '',
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
                const Icon(Icons.verified, color: AppColors.accentGold, size: 16),
                SizedBox(width: width * 0.015),
                Text(
                  (_userData?['role'] ?? 'admin').toString().toUpperCase(),
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
        _statCard('📍', '5', 'Content', width),
        _statCard('📅', '12', 'Bookings', width),
        _statCard('👥', '48', 'Users', width),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label, double width) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.01),
        padding: EdgeInsets.all(width * 0.04),
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
            Text(emoji, style: TextStyle(fontSize: width * 0.06)),
            SizedBox(height: width * 0.01),
            Text(value,
                style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Text(label,
                style: TextStyle(
                    fontSize: width * 0.028, color: Colors.grey.shade600)),
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
              color: Colors.grey.shade800)),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
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
                          color: Colors.grey.shade800)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: width * 0.028,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: width * 0.035, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showAbout(double width) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore, color: AppColors.primary),
            SizedBox(width: 10),
            Text('TURIVA Admin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Management portal for TURIVA Tourism Platform.\n\n'
                  '© 2025 TURIVA. All rights reserved.',
            ),
            const SizedBox(height: 15),
            Text('Made with ❤️ in Tanzania 🇹🇿',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}