import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/image_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_button.dart';

class ReportComplaintScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final String siteLocation;

  const ReportComplaintScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.siteLocation = '',
  });

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final _descCtrl     = TextEditingController();
  final _siteIdCtrl   = TextEditingController();
  final _siteNameCtrl = TextEditingController();
  XFile? _image;
  double? _lat, _lng;
  String? _address;
  bool _fetchingLoc = false;
  bool _submitting  = false;

  // Stamp captured when image is picked
  DateTime? _capturedAt;

  // resolved site info (from QR image scan or manual entry)
  String _resolvedSiteId   = '';
  String _resolvedSiteName = '';
  bool   _lookingUpSite    = false;

  bool get _isManual => widget.siteId.isEmpty;

  @override
  void initState() {
    super.initState();
    _resolvedSiteId   = widget.siteId;
    _resolvedSiteName = widget.siteName;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _siteIdCtrl.dispose();
    _siteNameCtrl.dispose();
    super.dispose();
  }

  // ── QR image upload: pick image and decode QR from it ──────────────────────
  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _lookingUpSite = true);
    try {
      // mobile_scanner can't decode from file on web; use the site_id field as fallback
      // We read the filename/path as a hint and ask user to confirm
      // For a real implementation, a QR decode library would be used here
      // For now: show the image and let user confirm/enter site ID
      _snack('QR image selected. Please verify the Site ID below.', err: false);
      setState(() {
        _siteIdCtrl.text = '';
      });
    } finally {
      setState(() => _lookingUpSite = false);
    }
  }

  // ── Look up site by manually entered ID ────────────────────────────────────
  Future<void> _lookupSite() async {
    final id = _siteIdCtrl.text.trim();
    if (id.isEmpty) { _snack('Enter a Site ID', err: true); return; }

    setState(() => _lookingUpSite = true);
    try {
      final data = await ApiService.getSiteByQrPublic(id);
      setState(() {
        _resolvedSiteId   = id;
        _resolvedSiteName = data['site_name'] ?? data['name'] ?? id;
        _siteNameCtrl.text = _resolvedSiteName;
      });
      _snack('Site found: $_resolvedSiteName');
    } catch (_) {
      _snack('Site not found. You can still submit with this ID.', err: true);
      setState(() {
        _resolvedSiteId   = id;
        _resolvedSiteName = _siteNameCtrl.text.trim().isNotEmpty
            ? _siteNameCtrl.text.trim()
            : id;
      });
    } finally {
      setState(() => _lookingUpSite = false);
    }
  }

  Future<void> _pickImage() async {
    final f = await ImageService.pickImage(context);
    if (f != null) {
      setState(() {
        _image = f;
        _capturedAt = DateTime.now();
      });
      // Auto-fetch location when image is picked if not already fetched
      if (_lat == null) _fetchLocation();
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLoc = true);
    final r = await LocationService.getCurrentLocation();
    if (r.success) {
      final addr = await LocationService.reverseGeocode(r.latitude!, r.longitude!);
      setState(() { _lat = r.latitude; _lng = r.longitude; _address = addr; });
    } else if (mounted) {
      _snack(r.error!, err: true);
    }
    setState(() => _fetchingLoc = false);
  }

  Future<void> _submit() async {
    final effectiveSiteId = _isManual ? _resolvedSiteId : widget.siteId;

    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please enter a description', err: true); return;
    }
    if (_image == null) {
      _snack('Please attach a photo', err: true); return;
    }
    if (_lat == null) {
      _snack('Please fetch your GPS location', err: true); return;
    }

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      await ApiService.submitComplaint(
        description: _descCtrl.text.trim(),
        location: _address ?? LocationService.format(_lat!, _lng!),
        token: token,
        siteId: effectiveSiteId,
      );
      if (mounted) {
        _snack('Complaint submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), err: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool err = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: err ? AppTheme.error : AppTheme.success,
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.citizen,
        foregroundColor: Colors.white,
        title: Text(_isManual ? 'Report Manually' : 'Report Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Site info section ─────────────────────────────────────────
            if (!_isManual) ...[
              // Came from QR scan — show auto-filled banner
              _SiteBanner(
                siteId: widget.siteId,
                siteName: widget.siteName,
                siteLocation: widget.siteLocation,
              ),
            ] else ...[
              // Manual entry — site ID input + QR image upload
              Container(
                padding: const EdgeInsets.all(AppTheme.spMD),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.info.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.info, size: 16),
                      const SizedBox(width: 8),
                      Text('Site Information',
                          style: AppTheme.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.info)),
                    ]),
                    AppTheme.gapSM,
                    Text(
                      'Enter the Site ID manually or upload a QR code image from your gallery.',
                      style: AppTheme.caption,
                    ),
                    AppTheme.gapMD,

                    // QR image upload button
                    OutlinedButton.icon(
                      onPressed: _lookingUpSite ? null : _pickQrImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.citizen,
                        side: const BorderSide(color: AppTheme.citizen),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Upload QR Image from Gallery'),
                    ),
                    AppTheme.gapSM,

                    // Site ID field + lookup
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _siteIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Site ID (e.g. SITE_ABC12345)',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                          onSubmitted: (_) => _lookupSite(),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spSM),
                      _lookingUpSite
                          ? const SizedBox(
                              width: 36, height: 36,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton.filled(
                              onPressed: _lookupSite,
                              icon: const Icon(Icons.search_rounded),
                              style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.citizen,
                                  foregroundColor: Colors.white),
                            ),
                    ]),

                    if (_resolvedSiteName.isNotEmpty &&
                        _resolvedSiteName != 'Manual Report') ...[
                      AppTheme.gapSM,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          border: Border.all(
                              color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_resolvedSiteName,
                                style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            AppTheme.gapMD,

            // ── Photo picker ──────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: _image != null ? AppTheme.citizen : AppTheme.divider,
                    width: _image != null ? 1.5 : 1,
                  ),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 40, color: AppTheme.textHint),
                          AppTheme.gapSM,
                          Text('Tap to add photo', style: AppTheme.bodySmall),
                          AppTheme.gapXS,
                          Text('Camera or Gallery', style: AppTheme.caption),
                        ],
                      )
                    : Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 15),
                            ),
                          ),
                        ),
                      ]),
              ),
            ),
            AppTheme.gapMD,

            // ── Location + date stamp (shown after image is picked) ───────
            if (_image != null && _capturedAt != null)
              _StampBanner(
                capturedAt: _capturedAt!,
                location: _fetchingLoc
                    ? 'Fetching location…'
                    : (_address ??
                        (_lat != null
                            ? LocationService.format(_lat!, _lng!)
                            : 'Location not fetched')),
                color: AppTheme.citizen,
              ),

            // ── Description ───────────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText: 'What did you observe at the site?',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description_outlined),
                ),
              ),
            ),
            AppTheme.gapMD,

            // ── GPS row ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spMD, vertical: AppTheme.spSM + 2),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: _lat != null ? AppTheme.citizen : AppTheme.divider,
                  width: _lat != null ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.location_on_rounded,
                    color: _lat != null ? AppTheme.citizen : AppTheme.textHint,
                    size: 20),
                const SizedBox(width: AppTheme.spSM + 2),
                Expanded(
                  child: _fetchingLoc
                      ? Text('Fetching location…', style: AppTheme.caption)
                      : Text(
                          _lat != null
                              ? (_address ?? LocationService.format(_lat!, _lng!))
                              : 'Location not fetched',
                          style: AppTheme.bodySmall.copyWith(
                            color: _lat != null
                                ? AppTheme.textPrimary
                                : AppTheme.textHint,
                          ),
                        ),
                ),
                if (_fetchingLoc)
                  const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  TextButton(
                    onPressed: _fetchLocation,
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.citizen,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 32)),
                    child: Text(_lat != null ? 'Refresh' : 'Fetch GPS'),
                  ),
              ]),
            ),
            AppTheme.gapXL,

            LoadingButton(
              isLoading: _submitting,
              label: 'Submit Complaint',
              color: AppTheme.citizen,
              icon: Icons.send_rounded,
              onPressed: _submit,
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
  final Color color;
  const _StampBanner({
    required this.capturedAt,
    required this.location,
    required this.color,
  });

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
      margin: const EdgeInsets.only(bottom: AppTheme.spMD),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: color),
            const SizedBox(width: 6),
            Text(_fmtDate(capturedAt),
                style: TextStyle(fontSize: 12, color: color,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            Icon(Icons.location_on_rounded, size: 13, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(location,
                  style: TextStyle(fontSize: 12, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Site banner (QR-scanned) ──────────────────────────────────────────────────
class _SiteBanner extends StatelessWidget {
  final String siteId;
  final String siteName;
  final String siteLocation;
  const _SiteBanner(
      {required this.siteId,
      required this.siteName,
      required this.siteLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.qr_code_scanner, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text('Site: $siteId',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.business, size: 13, color: Colors.black54),
            const SizedBox(width: 6),
            Expanded(
              child: Text(siteName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
          if (siteLocation.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on, size: 13, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(siteLocation,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
