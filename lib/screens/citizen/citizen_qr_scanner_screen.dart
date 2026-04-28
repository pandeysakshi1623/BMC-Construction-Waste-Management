import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import 'report_complaint_screen.dart';

class CitizenQrScannerScreen extends StatefulWidget {
  const CitizenQrScannerScreen({super.key});

  @override
  State<CitizenQrScannerScreen> createState() =>
      _CitizenQrScannerScreenState();
}

class _CitizenQrScannerScreenState extends State<CitizenQrScannerScreen> {
  bool _isProcessing = false;
  bool _loading = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extracts clean site_id from QR string.
  /// "SITE_ID:SITE_ABC123|CONTRACTOR:...|NAME:..." → "SITE_ABC123"
  /// "SITE_ABC123" → "SITE_ABC123"
  String _extractSiteId(String raw) {
    print('RAW QR: $raw');
    final siteId = raw
        .split('|')[0]                 // take first segment before |
        .replaceFirst('SITE_ID:', '')  // strip prefix if present
        .trim();
    print('EXTRACTED SITE ID: $siteId');
    return siteId;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _loading) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    // Stop camera immediately — prevents flickering + repeated detections
    await _controller.stop();

    final siteId = _extractSiteId(rawValue);

    // Validate format before hitting API
    if (!siteId.startsWith('SITE_')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid QR code — not a site QR'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isProcessing = false);
        await _controller.start();
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await ApiService.getSiteByQrPublic(siteId);

      if (!mounted) return;
      setState(() { _loading = false; _isProcessing = false; });

      // Navigate — do NOT restart camera after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportComplaintScreen(
            siteId: siteId,
            siteName: data['site_name'] ?? data['name'] ?? siteId,
            siteLocation: data['location'] ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().contains('not found')
          ? 'Site not found — check QR code'
          : e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));

      // Reset and allow re-scan only on error
      setState(() { _loading = false; _isProcessing = false; });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Site QR to Report'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Scan frame overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instruction banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scan the QR code at the construction site to report a complaint',
                    style: TextStyle(
                        color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                ),
              ]),
            ),
          ),

          // Bottom status
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(children: [
              if (_loading)
                const CircularProgressIndicator(color: Colors.green)
              else
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white54, size: 28),
              const SizedBox(height: 12),
              Text(
                _loading
                    ? 'Fetching site info...'
                    : 'Point camera at site QR code',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
