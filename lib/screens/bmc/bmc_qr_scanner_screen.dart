import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class BmcQrScannerScreen extends StatefulWidget {
  const BmcQrScannerScreen({super.key});

  @override
  State<BmcQrScannerScreen> createState() => _BmcQrScannerScreenState();
}

class _BmcQrScannerScreenState extends State<BmcQrScannerScreen> {
  bool _isProcessing = false;
  bool _loading = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extracts site_id from QR string.
  /// Backend stores full "SITE_XXXXXXXX" as site_id.
  /// QR data format: "SITE_ID:SITE_XXXX|CONTRACTOR:...|NAME:..."
  String _extractSiteId(String raw) {
    // Structured format: "SITE_ID:SITE_ABC123|..."
    if (raw.contains('SITE_ID:')) {
      return raw.split('|')[0].replaceFirst('SITE_ID:', '').trim();
    }
    // Already a plain site_id like "SITE_ABC123"
    if (raw.startsWith('SITE_')) return raw.trim();
    return raw.trim();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _loading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _isProcessing = true;
    await _controller.stop();

    final raw = barcode!.rawValue!;
    final siteId = _extractSiteId(raw);

    // Validate format
    if (!siteId.startsWith('SITE_')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid QR code — not a site QR'),
          backgroundColor: Colors.red,
        ));
      }
      _isProcessing = false;
      await _controller.start();
      return;
    }

    setState(() => _loading = true);

    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final siteData = await ApiService.getSiteByQr(siteId, token: token);

      if (!mounted) return;
      setState(() => _loading = false);
      _showSiteResult(siteData, siteId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSiteResult(Map<String, dynamic> site, String siteId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SiteResultSheet(
        site: site,
        siteId: siteId,
        onPenaltyAdded: () => Navigator.pop(context),
      ),
    ).then((_) {
      // Allow re-scan after sheet closes
      _isProcessing = false;
      _controller.start();
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('Error'),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isProcessing = false;
              _controller.start();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Site QR'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan frame overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF1A237E), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_loading)
                  const CircularProgressIndicator(
                      color: Color(0xFF1A237E)),
                const SizedBox(height: 12),
                Text(
                  _loading
                      ? 'Fetching site info...'
                      : 'Point camera at site QR code',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Site result bottom sheet ──────────────────────────────────────────────────
class _SiteResultSheet extends StatefulWidget {
  final Map<String, dynamic> site;
  final String siteId;
  final VoidCallback onPenaltyAdded;

  const _SiteResultSheet({
    required this.site,
    required this.siteId,
    required this.onPenaltyAdded,
  });

  @override
  State<_SiteResultSheet> createState() => _SiteResultSheetState();
}

class _SiteResultSheetState extends State<_SiteResultSheet> {
  void _openPenaltyDialog() {
    showDialog(
      context: context,
      builder: (_) => _PenaltyDialog(
        siteId: widget.siteId,
        siteName: widget.site['site_name'] ?? widget.site['name'] ?? widget.siteId,
        onSuccess: () {
          Navigator.pop(context); // close dialog
          widget.onPenaltyAdded();
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Text('$label: ',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Expanded(
              child: Text(value,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Site Found',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Card(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(Icons.business, 'Site',
                      site['site_name'] ?? site['name'] ?? '-'),
                  _row(Icons.location_on, 'Location',
                      site['location'] ?? '-'),
                  _row(Icons.engineering, 'Contractor',
                      site['contractor_id'] ?? site['contractor'] ?? '-'),
                  _row(Icons.delete_outline, 'Est. Waste',
                      '${site['waste_estimated'] ?? site['expected_waste'] ?? '-'} t'),
                  _row(Icons.delete, 'Actual Waste',
                      '${site['waste_actual'] ?? site['actual_waste'] ?? '-'} t'),
                  _row(Icons.info_outline, 'Status',
                      site['pickup_status'] ?? site['status'] ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openPenaltyDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.gavel),
            label: const Text('Add Penalty',
                style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Penalty dialog ────────────────────────────────────────────────────────────
class _PenaltyDialog extends StatefulWidget {
  final String siteId;
  final String siteName;
  final VoidCallback onSuccess;

  const _PenaltyDialog({
    required this.siteId,
    required this.siteName,
    required this.onSuccess,
  });

  @override
  State<_PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<_PenaltyDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid penalty amount'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      await ApiService.addPenalty(
        widget.siteId,
        double.parse(amountText),
        _reasonController.text.trim(),
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Penalty of ₹$amountText added for ${widget.siteName}'),
          backgroundColor: Colors.green,
        ));
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Penalty'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Site: ${widget.siteName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Penalty Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
