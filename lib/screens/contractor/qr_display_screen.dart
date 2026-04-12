import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/site_model.dart';

class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({super.key});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareQr(SiteModel site, String qrData) async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_${site.id}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code for site: ${site.name}\nCode: $qrData',
        subject: 'Site QR Code - ${site.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share QR code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = ModalRoute.of(context)!.settings.arguments as SiteModel;

    // Generate QR data: use backend qrCode if present, otherwise derive from site ID
    final qrData = site.qrCode.isNotEmpty ? site.qrCode : 'SITE_${site.id}';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Site QR Code'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(site.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(site.location,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          color: Colors.white,
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            errorStateBuilder: (_, __) => const Center(
                              child: Text('Failed to generate QR',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(qrData,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sharing ? null : () => _shareQr(site, qrData),
                      icon: _sharing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: Text(_sharing ? 'Sharing...' : 'Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/contractor/dashboard'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Dashboard'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
