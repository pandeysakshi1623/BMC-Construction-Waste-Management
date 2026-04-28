import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
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

  // Driver live location
  Map<String, dynamic>? _driverLocation;
  Timer? _locationPollTimer;

  // The pickup passed as argument (may be null if opened without pickup context)
  PickupModel? _pickup;

  // Upload is only allowed when driver has arrived
  bool get _isDriverArrived =>
      _pickup != null && _pickup!.status == PickupStatus.arrived;

  // Keep backward compat: if no pickup passed, fall back to old simulated flow
  bool get _isDriverVerified =>
      _pickup == null ? _legacyVerified : _isDriverArrived;

  // Legacy simulated verification (used when no pickup is passed)
  _CollectionStatus _legacyStatus = _CollectionStatus.notStarted;
  bool get _legacyVerified =>
      _legacyStatus == _CollectionStatus.inProgress ||
      _legacyStatus == _CollectionStatus.completed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PickupModel) {
        setState(() => _pickup = args);
        _startDriverLocationPoll(args);
      }
    });
  }

  void _startDriverLocationPoll(PickupModel pickup) {
    _fetchDriverLocation(pickup);
    // Only poll while driver hasn't arrived yet — stop once arrived/completed
    _locationPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final current = _pickup;
      if (current != null &&
          (current.status == PickupStatus.completed ||
           current.status == PickupStatus.failed)) {
        _locationPollTimer?.cancel();
        return;
      }
      _fetchDriverLocation(pickup);
    });
  }

  Future<void> _fetchDriverLocation(PickupModel pickup) async {
    if (pickup.driverId == null) return;
    final token = context.read<AuthProvider>().user?.token ?? '';
    final loc = await ApiService.getDriverLocation(pickup.driverId!, token: token);
    if (mounted) setState(() => _driverLocation = loc);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _locationPollTimer?.cancel();
    super.dispose();
  }

  void _driverStartCollection() {
    setState(() => _legacyStatus = _CollectionStatus.inProgress);
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
          _legacyStatus = _CollectionStatus.completed;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Proof uploaded and recorded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
        // Show rating dialog if we have a driver
        if (_pickup?.driverId != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) await _showRatingDialog();
        }
        await Future.delayed(const Duration(seconds: 1));
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

  // ── Rating dialog ───────────────────────────────────────────────────────────
  Future<void> _showRatingDialog() async {
    int selected = 0;
    final reviewCtrl = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.star_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Rate the Driver'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_pickup?.driverName ?? 'Driver',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setS(() => selected = i + 1),
                child: Icon(
                  i < selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber, size: 36,
                ),
              )),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Optional review…',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: selected == 0 ? null : () async {
                Navigator.pop(ctx);
                try {
                  final token = context.read<AuthProvider>().user?.token ?? '';
                  await ApiService.submitDriverRating(
                    driverId: _pickup!.driverId!,
                    rating: selected,
                    review: reviewCtrl.text.trim(),
                    token: token,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Rating submitted — thank you!'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status badge ────────────────────────────────────────────────────────────
  Widget _statusBadge() {
    String label; Color color; IconData icon;
    if (_pickup != null) {
      switch (_pickup!.status) {
        case PickupStatus.arrived:
          label = 'Driver Arrived'; color = Colors.teal; icon = Icons.location_on;
          break;
        case PickupStatus.inProgress:
          label = 'In Progress'; color = Colors.orange; icon = Icons.timelapse;
          break;
        case PickupStatus.completed:
          label = 'Completed'; color = Colors.green; icon = Icons.check_circle;
          break;
        default:
          label = 'Pending'; color = Colors.grey; icon = Icons.hourglass_empty;
      }
    } else {
      switch (_legacyStatus) {
        case _CollectionStatus.notStarted:
          label = 'Not Started'; color = Colors.red; icon = Icons.radio_button_unchecked;
          break;
        case _CollectionStatus.inProgress:
          label = 'In Progress'; color = Colors.orange; icon = Icons.timelapse;
          break;
        case _CollectionStatus.completed:
          label = 'Completed'; color = Colors.green; icon = Icons.check_circle;
          break;
      }
    }

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
    // Accept either SiteModel (old flow) or PickupModel (new flow)
    final args = ModalRoute.of(context)!.settings.arguments;
    final SiteModel site = args is SiteModel
        ? args
        : SiteModel(
            id: _pickup?.siteId ?? '',
            name: _pickup?.siteName ?? 'Site',
            location: _pickup?.location ?? '',
            area: 0, expectedWaste: 0,
            qrCode: '', pickupStatus: '', actualWaste: 0);

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

            // ── Driver info + arrival status ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDriverVerified
                      ? Colors.teal.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.local_shipping,
                        color: _isDriverVerified ? Colors.teal : Colors.grey,
                        size: 18),
                    const SizedBox(width: 8),
                    Text('Driver Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isDriverVerified
                                ? Colors.teal
                                : Colors.grey[700])),
                  ]),
                  const SizedBox(height: 8),
                  // Real driver details from pickup
                  if (_pickup != null) ...[
                    if (_pickup!.driverName != null)
                      _driverRow(Icons.person_outline,
                          'Driver: ${_pickup!.driverName!}'),
                    if (_pickup!.driverPhone != null)
                      _driverRow(Icons.phone_outlined,
                          'Phone: ${_pickup!.driverPhone!}'),
                    if (_pickup!.driverVehicle != null)
                      _driverRow(Icons.local_shipping_outlined,
                          'Vehicle: ${_pickup!.driverVehicle!}'),
                    const SizedBox(height: 6),
                    // Live location
                    _driverRow(
                      Icons.location_on_outlined,
                      _driverLocation != null
                          ? 'Location: ${(_driverLocation!['latitude'] as num).toStringAsFixed(4)}, '
                              '${(_driverLocation!['longitude'] as num).toStringAsFixed(4)}'
                          : 'Location: not available',
                    ),
                    const SizedBox(height: 6),
                    // Arrival lock message
                    if (!_isDriverArrived)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(children: [
                          Icon(Icons.lock_outline,
                              color: Colors.orange, size: 14),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Upload allowed only after driver reaches site',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: const Row(children: [
                          Icon(Icons.check_circle,
                              color: Colors.teal, size: 14),
                          SizedBox(width: 6),
                          Text('Driver has arrived — upload unlocked',
                              style: TextStyle(
                                  color: Colors.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ] else ...[
                    // Legacy simulated flow (no pickup passed)
                    Text(
                      _legacyStatus == _CollectionStatus.notStarted
                          ? '⏳ Waiting for driver to start waste collection...'
                          : _legacyStatus == _CollectionStatus.inProgress
                              ? '🚛 Collection in progress — ready for proof upload'
                              : '✅ Collection completed and proof recorded',
                      style: TextStyle(
                          fontSize: 13,
                          color: _legacyVerified
                              ? Colors.green[700]
                              : Colors.grey[600]),
                    ),
                    if (_legacyStatus == _CollectionStatus.notStarted) ...[
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
                  : 'Awaiting Driver Arrival',
              color: _isDriverVerified ? Colors.blue : Colors.grey,
              icon: _isDriverVerified ? Icons.upload : Icons.lock_outline,
              onPressed: _isDriverVerified ? () => _submit(site) : null,
            ),

            if (!_isDriverVerified) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _pickup != null
                      ? 'Upload unlocks when driver marks "Reached Location"'
                      : 'Upload will be enabled once driver starts collection',
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

// ── Driver info row helper ────────────────────────────────────────────────────
Widget _driverRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ]),
    );

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
