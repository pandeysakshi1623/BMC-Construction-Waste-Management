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
  /// Required — complaint must be linked to a site via QR scan
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
  final _descCtrl = TextEditingController();
  XFile? _image;
  double? _lat, _lng;
  String? _address;
  bool _fetchingLoc = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Guard — should never reach here without a siteId
    if (widget.siteId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please scan a site QR code first'),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final f = await ImageService.pickImage(context);
    if (f != null) setState(() => _image = f);
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLoc = true);
    final r = await LocationService.getCurrentLocation();
    if (r.success) {
      final addr =
          await LocationService.reverseGeocode(r.latitude!, r.longitude!);
      setState(() {
        _lat = r.latitude;
        _lng = r.longitude;
        _address = addr;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.error!), backgroundColor: AppTheme.error));
    }
    setState(() => _fetchingLoc = false);
  }

  Future<void> _submit() async {
    if (widget.siteId.isEmpty) {
      _snack('Site ID missing — please scan QR again', err: true);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please enter a description', err: true);
      return;
    }
    if (_image == null) {
      _snack('Please attach a photo', err: true);
      return;
    }
    if (_lat == null) {
      _snack('Please fetch your GPS location', err: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      await ApiService.submitComplaint(
        description: _descCtrl.text.trim(),
        location: _address ?? LocationService.format(_lat!, _lng!),
        token: token,
        siteId: widget.siteId,
      );
      if (mounted) {
        _snack('Complaint submitted successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), err: true);
      }
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
        title: const Text('Report Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Site banner (auto-filled from QR) ──────────────────────
            Container(
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
                    const Icon(Icons.qr_code_scanner,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('Complaint for Site: ${widget.siteId}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.business,
                        size: 13, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(widget.siteName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  if (widget.siteLocation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on,
                          size: 13, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(widget.siteLocation,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700])),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            AppTheme.gapMD,

            // ── Photo picker ────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: _image != null
                        ? AppTheme.citizen
                        : AppTheme.divider,
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
                          Text('Tap to add photo',
                              style: AppTheme.bodySmall),
                          AppTheme.gapXS,
                          Text('Camera or Gallery',
                              style: AppTheme.caption),
                        ],
                      )
                    : Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
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
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull),
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

            // ── Description ─────────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText: 'What did you observe?',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description_outlined),
                ),
              ),
            ),
            AppTheme.gapMD,

            // ── GPS row ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spMD,
                  vertical: AppTheme.spSM + 2),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color:
                      _lat != null ? AppTheme.citizen : AppTheme.divider,
                  width: _lat != null ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.location_on_rounded,
                    color: _lat != null
                        ? AppTheme.citizen
                        : AppTheme.textHint,
                    size: 20),
                const SizedBox(width: AppTheme.spSM + 2),
                Expanded(
                  child: _fetchingLoc
                      ? Text('Fetching location…', style: AppTheme.caption)
                      : Text(
                          _lat != null
                              ? (_address ??
                                  LocationService.format(_lat!, _lng!))
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  TextButton(
                    onPressed: _fetchLocation,
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.citizen,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 32)),
                    child:
                        Text(_lat != null ? 'Refresh' : 'Fetch GPS'),
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
