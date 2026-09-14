import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class TestUploadScreen extends StatefulWidget {
  const TestUploadScreen({super.key});

  @override
  State<TestUploadScreen> createState() => _TestUploadScreenState();
}

class _TestUploadScreenState extends State<TestUploadScreen> {
  final CloudinaryService _cloudinary = CloudinaryService();
  String? _uploadedUrl;
  bool _isLoading = false;

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      String? url;

      if (kIsWeb) {
        // Web: Use bytes
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinary.uploadImageBytes(bytes, folder: 'turiva/test');
      } else {
        // Mobile: Use File
        url = await _cloudinary.uploadImage(
          File(pickedFile.path),
          folder: 'turiva/test',
        );
      }

      setState(() {
        _uploadedUrl = url;
        _isLoading = false;
      });

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Cloudinary Upload'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndUpload,
              icon: const Icon(Icons.upload),
              label: const Text('Pick & Upload Image'),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const CircularProgressIndicator(),

            if (_uploadedUrl != null) ...[
              const Text('✅ Uploaded Image:'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _uploadedUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                _uploadedUrl!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}