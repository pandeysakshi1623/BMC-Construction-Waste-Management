import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProofHistoryScreen extends StatefulWidget {
  final SiteModel site;
  const ProofHistoryScreen({super.key, required this.site});

  @override
  State<ProofHistoryScreen> createState() => _ProofHistoryScreenState();
}

class _ProofHistoryScreenState extends State<ProofHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getProofHistory(
          widget.site.id, token: token);
      setState(() => _history = data);
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Formats ISO timestamp → "12 Apr 2026, 10:30"
  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('History — ${widget.site.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _history.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: _history.length,
                        itemBuilder: (_, i) => _TimelineEntry(
                          entry: _history[i],
                          isLast: i == _history.length - 1,
                          formatTime: _formatTime,
                          baseUrl: ApiService.base,
                        ),
                      ),
                    ),
    );
  }
}

// ── Timeline entry ────────────────────────────────────────────────────────────
class _TimelineEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isLast;
  final String Function(String?) formatTime;
  final String baseUrl;

  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.formatTime,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = entry['image_url'] as String? ?? '';
    final waste = entry['actual_waste'];
    final timestamp = formatTime(entry['timestamp'] as String?);
    final status = entry['status'] as String? ?? 'Completed';
    final driver = entry['driver_name'] as String? ?? '';
    final location = entry['location'] as String? ?? '';

    final fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '$baseUrl$imageUrl';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.blue.withOpacity(0.25),
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14)),
                      child: Image.network(
                        fullImageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label + status badge
                        Row(
                          children: [
                            const Icon(Icons.assignment_turned_in,
                                size: 14, color: Colors.blue),
                            const SizedBox(width: 6),
                            const Text('Proof Uploaded',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.4)),
                              ),
                              child: Text(
                                '✔ $status',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Waste
                        _infoRow(Icons.recycling,
                            '${waste ?? '-'} tonnes collected',
                            Colors.teal),

                        // Timestamp
                        if (timestamp.isNotEmpty)
                          _infoRow(Icons.access_time, timestamp,
                              Colors.grey[600]!),

                        // Driver
                        if (driver.isNotEmpty)
                          _infoRow(Icons.local_shipping, driver,
                              Colors.indigo),

                        // Location
                        if (location.isNotEmpty)
                          _infoRow(Icons.location_on, location,
                              Colors.orange[700]!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No proof uploads yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 6),
            Text('Upload a proof to see history here',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
}
