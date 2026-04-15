import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final _picker = ImagePicker();

  /// Picks an image from gallery and returns XFile (works on web + mobile).
  static Future<XFile?> pickImage(BuildContext context) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      print('Selected image: ${picked.path}');
    } else {
      print('No image selected');
    }
    return picked;
  }

  /// Returns the correct preview widget for web and mobile.
  static Widget previewWidget(XFile image) {
    if (kIsWeb) {
      // On web, path is a blob URL — use Image.network
      return Image.network(image.path, fit: BoxFit.cover);
    } else {
      // On mobile, path is a real file path
      return Image.file(File(image.path), fit: BoxFit.cover);
    }
  }
}
