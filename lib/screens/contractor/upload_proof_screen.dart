import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../widgets/loading_button.dart';

class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({super.key});

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  XFile? _image;
  final _quantityController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageService.pickImage(context);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _submit(SiteModel site) async {
    if (_image == null) {
      _snack('Please attach a photo', isError: true); return;
    }
    if (_quantityController.text.isEmpty ||
        double.tryParse(_quantityController.text) == null) {
      _snack('Enter a valid waste quantity', isError: true); return;
    }

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final bytes = await _image!.readAsBytes();
      final ok = await ApiService.uploadProof(
        site.id,
        _image!.path,
        double.parse(_quantityController.text),
        token: token,
        imageBytes: bytes,
        imageName: _image!.name,
      );
      if (mounted) {
        _snack(ok ? 'Proof uploaded!' : 'Upload failed', isError: !ok);
        if (ok) Navigator.pop(context);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ));

  @override
  Widget build(BuildContext context) {
    final site = ModalRoute.of(context)!.settings.arguments as SiteModel;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Upload Disposal Proof'),
        backgroundColor: Colors.blue,
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
                child: Row(children: [
                  const Icon(Icons.business, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(site.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
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
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Tap to add photo',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      )
                    : Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ImageService.previewWidget(_image!),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual Waste Quantity (tonnes)',
                prefixIcon: Icon(Icons.delete_outline),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            LoadingButton(
              isLoading: _submitting,
              label: 'Submit Proof',
              color: Colors.blue,
              icon: Icons.upload,
              onPressed: () => _submit(site),
            ),
          ],
        ),
      ),
    );
  }
}
