import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../services/location_service.dart';
import '../../widgets/loading_button.dart';

class UploadDisposalScreen extends StatefulWidget {
  const UploadDisposalScreen({super.key});

  @override
  State<UploadDisposalScreen> createState() => _UploadDisposalScreenState();
}

class _UploadDisposalScreenState extends State<UploadDisposalScreen> {
  XFile? _image;
  bool _submitting = false;

  // Stamp captured when image is picked
  DateTime? _capturedAt;
  String _capturedLocation = 'Fetching location…';

  Future<void> _pickImage() async {
    final file = await ImageService.pickImage(context);
    if (file != null) {
      final now = DateTime.now();
      setState(() {
        _image = file;
        _capturedAt = now;
        _capturedLocation = 'Fetching location…';
      });
      final result = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _capturedLocation = result.success
              ? '${result.latitude!.toStringAsFixed(5)}, ${result.longitude!.toStringAsFixed(5)}'
              : result.error ?? 'Location not available';
        });
        if (result.success) {
          final addr = await LocationService.reverseGeocode(
              result.latitude!, result.longitude!);
          if (mounted) setState(() => _capturedLocation = addr);
        }
      }
    }
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
      final bytes = await _image!.readAsBytes();
      final ok = await ApiService.uploadDisposalProof(
        pickup.id,
        _image!.path,
        token: token,
        imageBytes: bytes,
        imageName: _image!.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Proof uploaded!' : 'Upload failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ));
        // Return true so the caller (pickups_screen) can mark as completed
        if (ok) Navigator.pop(context, true);
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
            const SizedBox(height: 32),
            // ── Location + date stamp ─────────────────────────────────────
            if (_image != null && _capturedAt != null)
              _StampBanner(capturedAt: _capturedAt!, location: _capturedLocation),
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

// ── Stamp banner — shown below image after picking ────────────────────────────
class _StampBanner extends StatelessWidget {
  final DateTime capturedAt;
  final String location;
  const _StampBanner({required this.capturedAt, required this.location});

  String _fmtDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour24 = dt.hour;
    final h = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepOrange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 13,
                color: Colors.deepOrange.shade700),
            const SizedBox(width: 6),
            Text(_fmtDate(capturedAt),
                style: TextStyle(fontSize: 12,
                    color: Colors.deepOrange.shade800,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            Icon(Icons.location_on_rounded, size: 13,
                color: Colors.deepOrange.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(location,
                  style: TextStyle(fontSize: 12,
                      color: Colors.deepOrange.shade800),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}
