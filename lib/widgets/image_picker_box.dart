import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerBox extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const ImagePickerBox({super.key, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Tap to add photo',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image!,
                    fit: BoxFit.cover, width: double.infinity),
              ),
      ),
    );
  }
}

/// Helper to show camera/gallery bottom sheet
Future<File?> pickImageFromSheet(BuildContext context) async {
  File? result;
  final picker = ImagePicker();

  await showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () async {
              Navigator.pop(context);
              final picked =
                  await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
              if (picked != null) result = File(picked.path);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final picked =
                  await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (picked != null) result = File(picked.path);
            },
          ),
        ],
      ),
    ),
  );
  return result;
}
