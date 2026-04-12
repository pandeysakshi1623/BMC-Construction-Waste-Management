import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/pickup_model.dart';
import '../../services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _scanned = false;
  bool _validating = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture, PickupModel pickup) async {
    if (_scanned || _validating) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() { _scanned = true; _validating = true; });
    await _controller.stop();

    final code = barcode!.rawValue!;
    final isValid = await ApiService.validateQrCode(code);

    setState(() => _validating = false);

    if (!mounted) return;

    if (isValid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('QR Valid'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Site: ${pickup.siteName}'),
              const SizedBox(height: 4),
              Text('Code: $code',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to pickups
              },
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                    context, '/driver/upload-disposal',
                    arguments: pickup);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: const Text('Upload Proof',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Invalid QR'),
          ]),
          content: const Text('This QR code does not match any registered site.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _scanned = false);
                _controller.start();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ModalRoute.of(context)!.settings.arguments as PickupModel;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Site QR Code'),
        backgroundColor: Colors.deepOrange,
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
            onDetect: (capture) => _onDetect(capture, pickup),
          ),
          // Overlay frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_validating)
                  const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  _validating
                      ? 'Validating...'
                      : 'Point camera at the site QR code',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Site: ${pickup.siteName}',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
