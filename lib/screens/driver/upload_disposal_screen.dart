import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../widgets/loading_button.dart';

class UploadDisposalScreen extends StatefulWidget {
  const UploadDisposalScreen({super.key});

  @override
  State<UploadDisposalScreen> createState() => _UploadDisposalScreenState();
}

class _UploadDisposalScreenState extends State<UploadDisposalScreen> {
  File? _image;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final file = await ImageService.pickImage(context);
    print('Image state: $file');
    if (file != null) setState(() => _image = file);
  }

  Future<void> _submit(PickupModel pickup) async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please attach a photo'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final ok = await ApiService.uploadDisposalProof(
          pickup.id, _image!.path, token: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Proof uploaded!' : 'Upload failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ));
        if (ok) Navigator.pushReplacementNamed(context, '/driver/pickups');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ModalRoute.of(context)!.settings.arguments as PickupModel;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Upload Disposal Proof'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Details',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(pickup.siteName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(pickup.location,
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text('Type: ${pickup.wasteType}',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 52, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Tap to add disposal photo',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      )
                    : Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ]),
              ),
            ),
            const SizedBox(height: 32),
            LoadingButton(
              isLoading: _submitting,
              label: 'Submit Proof',
              color: Colors.deepOrange,
              icon: Icons.upload,
              onPressed: () => _submit(pickup),
            ),
          ],
        ),
      ),
    );
  }
}
