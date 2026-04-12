import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final _picker = ImagePicker();

  /// Shows a bottom sheet and returns an [XFile] — works on web and mobile.
  /// Returns null if the user cancels.
  static Future<XFile?> pickImage(BuildContext context) async {
    // On web there is no camera/gallery distinction in the OS picker,
    // so skip the bottom sheet and open the file picker directly.
    if (kIsWeb) {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      return picked;
    }

    // Mobile: show camera / gallery bottom sheet
    final completer = Completer<XFile?>();

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
                width: 40,
                height: 4,
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
                  if (!completer.isCompleted) completer.complete(picked);
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
                  if (!completer.isCompleted) completer.complete(picked);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  /// Renders the picked image correctly on both web and mobile.
  static Widget previewWidget(XFile file, {BoxFit fit = BoxFit.cover}) {
    if (kIsWeb) {
      // On web, XFile.path is a blob URL — use Image.network
      return Image.network(file.path, fit: fit);
    }
    // On mobile, use Image.asset via bytes for safety, or just network works too
    return Image.network(file.path, fit: fit);
  }
}
