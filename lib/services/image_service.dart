import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final _picker = ImagePicker();

  /// Shows a bottom sheet and returns the picked File, or null if cancelled.
  static Future<File?> pickImage(BuildContext context) async {
    File? result;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Select Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                      source: ImageSource.camera, imageQuality: 75);
                  if (picked != null) result = File(picked.path);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 75);
                  if (picked != null) result = File(picked.path);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    return result;
  }
}
