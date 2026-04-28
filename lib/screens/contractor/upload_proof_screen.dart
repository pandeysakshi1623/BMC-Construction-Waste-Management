import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../services/location_service.dart';
import '../../widgets/loading_button.dart';
import 'proof_history_screen.dart';

// ── Collection status enum ────────────────────────────────────────────────────
enum _CollectionStatus { notStarted, inProgress, completed }

class UploadProofScreen extends StatefulWidget {
  const UploadProofScreen({super.key});

  @override
  State<UploadProofScreen> createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  XFile? _image;
  String? _uploadedImageUrl;
  final _quantityController = TextEditingController();
  bool _submitting = false;

  // Stamp captured when image is picked
  DateTime? _capturedAt;
  String _capturedLocation = 'Fetching location…';

  // Verification state
  _CollectionStatus _status = _CollectionStatus.notStarted;
  bool get _isDriverVerified => _status == _CollectionStatus.inProgress ||
      _status == _CollectionStatus.completed;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // ── Driver simulated action ─────────────────────────────────────────────────
  void _driverStartCollection() {
    setState(() => _status = _CollectionStatus.inProgress);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ Driver confirmed: Collection in progress'),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 2),
    ));
  }

  // ── Image picker ────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    if (!_isDriverVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Upload allowed only after driver verification'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final file = await ImageService.pickImage(context);
    if (file != null) {
      // Stamp date + fetch location at the moment of capture
      final now = DateTime.now();
      setState(() {
        _image = file;
        _uploadedImageUrl = null;
        _capturedAt = now;
        _capturedLocation = 'Fetching location…';
      });
      // Fetch location in background
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

  // ── Submit with confirmation dialog ────────────────────────────────────────
  Future<void> _submit(SiteModel site) async {
    if (!_isDriverVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Upload allowed only after driver verification'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_image == null) {
      _snack('Please attach a photo', isError: true); return;
    }
    if (_quantityController.text.isEmpty ||
        double.tryParse(_quantityController.text) == null) {
      _snack('Enter a valid waste quantity', isError: true); return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.verified_user, color: Colors.blue),
          SizedBox(width: 8),
          Text('Confirm Upload'),
        ]),
        content: const Text(
          'Confirm that this proof is being uploaded during active waste '
          'collection verified by the driver.\n\n'
          'False submissions may result in penalties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final bytes = await _image!.readAsBytes();
      final imageUrl = await ApiService.uploadProof(
        site.id,
        _image!.path,
        double.parse(_quantityController.text),
        token: token,
        imageBytes: bytes,
        imageName: _image!.name,
        driverVerified: true,
      );

      if (mounted) {
        setState(() {
          _uploadedImageUrl =
              imageUrl != null ? '${ApiService.base}$imageUrl' : null;
          _image = null;
          _status = _CollectionStatus.completed;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Proof uploaded and recorded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
        // Auto-navigate back after short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
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

  // ── Status badge ────────────────────────────────────────────────────────────
  Widget _statusBadge() {
    final (label, color, icon) = switch (_status) {
      _CollectionStatus.notStarted => (
          'Not Started',
          Colors.red,
          Icons.radio_button_unchecked
        ),
      _CollectionStatus.inProgress => (
          'In Progress',
          Colors.orange,
          Icons.timelapse
        ),
      _CollectionStatus.completed => (
          'Completed',
          Colors.green,
          Icons.check_circle
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final site = ModalRoute.of(context)!.settings.arguments as SiteModel;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Upload Disposal Proof'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => ProofHistoryScreen(site: site))),
            icon: const Icon(Icons.history, color: Colors.white, size: 18),
            label: const Text('History',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Government compliance notice ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Government Compliance Notice',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          'Proof must ONLY be uploaded during active waste '
                          'collection. Fake or delayed uploads may result in '
                          'penalties under BMC regulations.',
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Site info + status ────────────────────────────────────────
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
                  _statusBadge(),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Driver verification panel ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDriverVerified
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      _isDriverVerified
                          ? Icons.local_shipping
                          : Icons.local_shipping_outlined,
                      color: _isDriverVerified ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Driver Verification',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDriverVerified
                              ? Colors.green
                              : Colors.grey[700]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    _status == _CollectionStatus.notStarted
                        ? '⏳ Waiting for driver to start waste collection...'
                        : _status == _CollectionStatus.inProgress
                            ? '🚛 Collection in progress — ready for proof upload'
                            : '✅ Collection completed and proof recorded',
                    style: TextStyle(
                        fontSize: 13,
                        color: _isDriverVerified
                            ? Colors.green[700]
                            : Colors.grey[600]),
                  ),
                  if (_status == _CollectionStatus.notStarted) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _driverStartCollection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Driver: Start Collection'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Post-upload preview ───────────────────────────────────────
            if (_uploadedImageUrl != null) ...[
              const Text('✅ Uploaded Proof',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _uploadedImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => ProofHistoryScreen(site: site))),
                icon: const Icon(Icons.history),
                label: const Text('View Full History'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Upload Another Proof',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],

            // ── Image picker ──────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: _isDriverVerified ? Colors.white : Colors.grey[100],
                  border: Border.all(
                    color: _isDriverVerified
                        ? Colors.grey.shade300
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 44,
                              color: _isDriverVerified
                                  ? Colors.grey[400]
                                  : Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            _isDriverVerified
                                ? 'Tap to add photo'
                                : 'Locked — awaiting driver verification',
                            style: TextStyle(
                                color: _isDriverVerified
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                                fontSize: 13),
                          ),
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
            const SizedBox(height: 14),

            // ── Location + date stamp (shown after image is picked) ───────
            if (_image != null && _capturedAt != null)
              _StampBanner(capturedAt: _capturedAt!, location: _capturedLocation),

            // ── Waste quantity ────────────────────────────────────────────
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              enabled: _isDriverVerified,
              decoration: InputDecoration(
                labelText: 'Actual Waste Quantity (tonnes)',
                prefixIcon: const Icon(Icons.delete_outline),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor:
                    _isDriverVerified ? Colors.white : Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit button ─────────────────────────────────────────────
            LoadingButton(
              isLoading: _submitting,
              label: _isDriverVerified
                  ? 'Submit Verified Proof'
                  : 'Awaiting Driver Verification',
              color: _isDriverVerified ? Colors.blue : Colors.grey,
              icon: _isDriverVerified ? Icons.upload : Icons.lock_outline,
              onPressed: _isDriverVerified ? () => _submit(site) : null,
            ),

            if (!_isDriverVerified) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Upload will be enabled once driver starts collection',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(_fmtDate(capturedAt),
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            Icon(Icons.location_on_rounded, size: 13, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(location,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}
