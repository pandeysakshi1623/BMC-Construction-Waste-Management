import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class BmcTruckApprovalScreen extends StatefulWidget {
  const BmcTruckApprovalScreen({super.key});

  @override
  State<BmcTruckApprovalScreen> createState() =>
      _BmcTruckApprovalScreenState();
}

class _BmcTruckApprovalScreenState extends State<BmcTruckApprovalScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pickups = [];
  bool _loading = true;
  String? _error;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Categorise pickups ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _ongoing => _pickups.where((p) {
        final s = (p['status'] ?? '').toString().toLowerCase();
        return s == 'accepted' || s == 'in progress' || s == 'inprogress';
      }).toList();

  List<Map<String, dynamic>> get _upcoming => _pickups.where((p) {
        final s = (p['status'] ?? '').toString().toLowerCase();
        return s == 'pending';
      }).toList();

  List<Map<String, dynamic>> get _past => _pickups.where((p) {
        final s = (p['status'] ?? '').toString().toLowerCase();
        return s == 'completed' || s == 'failed' ||
            s == 'approved' || s == 'rejected';
      }).toList();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      print('TOKEN (BmcTruckApproval load): $token');
      final data = await ApiService.getBmcPickups(token: token);
      setState(() => _pickups = data);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Do NOT redirect to login — just show the error
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('All Pickups'),
        backgroundColor: AppTheme.bmc,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Ongoing (${_ongoing.length})'),
            Tab(text: 'Upcoming (${_upcoming.length})'),
            Tab(text: 'Past (${_past.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _PickupList(pickups: _ongoing,  emptyMessage: 'No ongoing pickups'),
                    _PickupList(pickups: _upcoming, emptyMessage: 'No upcoming pickups'),
                    _PickupList(pickups: _past,     emptyMessage: 'No past pickups'),
                  ],
                ),
    );
  }
}

// ── Scrollable list per tab ───────────────────────────────────────────────────
class _PickupList extends StatelessWidget {
  final List<Map<String, dynamic>> pickups;
  final String emptyMessage;

  const _PickupList({
    required this.pickups,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (pickups.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spMD),
        itemCount: pickups.length,
        itemBuilder: (_, i) => _TruckCard(pickup: pickups[i]),
      ),
    );
  }
}

// ── Individual pickup card ────────────────────────────────────────────────────
class _TruckCard extends StatelessWidget {
  final Map<String, dynamic> pickup;

  const _TruckCard({required this.pickup});

  Color _statusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'approved':   return AppTheme.success;
      case 'completed':  return AppTheme.success;
      case 'rejected':   return AppTheme.error;
      case 'failed':     return AppTheme.error;
      case 'inprogress': return const Color(0xFF3949AB);
      case 'accepted':   return AppTheme.info;
      default:           return AppTheme.pending;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = pickup['status'] ?? 'Pending';
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spMD),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Text(
                  pickup['site_name'] ?? 'Unknown Site',
                  style: AppTheme.heading3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: AppTheme.spSM),

            // Info rows
            _infoRow(Icons.location_on_outlined,
                pickup['location']?.toString().isNotEmpty == true
                    ? pickup['location']
                    : 'N/A'),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today_outlined,
                _formatDate(pickup['scheduled_date']?.toString())),
            if (pickup['driver_name'] != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.person_outline, pickup['driver_name'].toString()),
            ],
            if (pickup['driver_vehicle'] != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.local_shipping_outlined,
                  pickup['driver_vehicle'].toString()),
            ],
            if (pickup['waste_type'] != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.delete_outline_rounded,
                  pickup['waste_type'].toString()),
            ],
            // Show proof image thumbnail if available
            if (pickup['disposal_proof_url'] != null) ...[
              const SizedBox(height: AppTheme.spSM),
              _ProofThumbnail(proofUrl: pickup['disposal_proof_url'].toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: AppTheme.textHint),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: AppTheme.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]);
}

// ── Proof thumbnail ───────────────────────────────────────────────────────────
class _ProofThumbnail extends StatelessWidget {
  final String proofUrl;
  const _ProofThumbnail({required this.proofUrl});

  String get _fullUrl {
    if (proofUrl.startsWith('http')) return proofUrl;
    // Backend serves static files from /static/
    return 'http://localhost:8000$proofUrl';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppBar(
              title: const Text('Disposal Proof'),
              backgroundColor: AppTheme.bmc,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(
              _fullUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Could not load image'),
                ]),
              ),
            ),
          ]),
        ),
      ),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppTheme.success.withOpacity(0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(
              _fullUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.image_outlined,
                    color: Colors.grey, size: 32),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Tap to view proof',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spLG),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}
