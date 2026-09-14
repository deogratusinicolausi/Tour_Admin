import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CloudinaryService {
  // ⭐️ Badilisha hizi na zako za Cloudinary
  static const String _cloudName = 'zy9bpr85'; // ← Weka yako
  static const String _uploadPreset = 'turiva_admin'; // ← Weka yako

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  // ⭐️ Upload single image from File (mobile)
  Future<String?> uploadImage(File file, {String folder = 'turiva'}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('🔥 Cloudinary upload error: $e');
      return null;
    }
  }

  // ⭐️ Upload image from bytes (web)
  Future<String?> uploadImageBytes(Uint8List bytes, {String folder = 'turiva'}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: 'upload_${DateTime.now().millisecondsSinceEpoch}',
          resourceType: CloudinaryResourceType.Image,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('🔥 Cloudinary upload error: $e');
      return null;
    }
  }

  // ⭐️ Upload multiple images
  Future<List<String>> uploadMultipleImages(
      List<File> files, {
        String folder = 'turiva',
      }) async {
    List<String> urls = [];
    for (File file in files) {
      String? url = await uploadImage(file, folder: folder);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // ⭐️ Upload video (kama unataka baadaye)
  Future<String?> uploadVideo(File file, {String folder = 'turiva/videos'}) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Video,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('🔥 Cloudinary video upload error: $e');
      return null;
    }
  }

// ⭐️ Delete image (optional — inahitaji API secret, sio salama kwenye client)
// Kwa hiyo tutatumia Cloud Functions baadaye
}