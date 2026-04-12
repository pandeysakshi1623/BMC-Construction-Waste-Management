import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class BmcTruckApprovalScreen extends StatefulWidget {
  const BmcTruckApprovalScreen({super.key});

  @override
  State<BmcTruckApprovalScreen> createState() =>
      _BmcTruckApprovalScreenState();
}

class _BmcTruckApprovalScreenState extends State<BmcTruckApprovalScreen> {
  List<Map<String, dynamic>> _pickups = [];
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
      final data = await ApiService.getBmcPickups(token: token);
      setState(() => _pickups = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String pickupId, String status) async {
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      await ApiService.approveTruck(pickupId, status, token: token);

      // Update local state
      setState(() {
        final idx = _pickups.indexWhere((p) => p['id'] == pickupId);
        if (idx != -1) _pickups[idx] = {..._pickups[idx], 'status': status};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Truck $status successfully'),
          backgroundColor:
              status == 'Approved' ? Colors.green : Colors.red,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Truck Approvals'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _pickups.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pickups.length,
                        itemBuilder: (_, i) => _TruckCard(
                          pickup: _pickups[i],
                          onApprove: () =>
                              _updateStatus(_pickups[i]['id'], 'Approved'),
                          onReject: () =>
                              _updateStatus(_pickups[i]['id'], 'Rejected'),
                        ),
                      ),
                    ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  final Map<String, dynamic> pickup;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TruckCard({
    required this.pickup,
    required this.onApprove,
    required this.onReject,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = pickup['status'] ?? 'Pending';
    final isDone =
        status == 'Approved' || status == 'Rejected';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pickup['site_name'] ?? 'Unknown Site',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor(status).withOpacity(0.4)),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on_outlined,
                pickup['location'] ?? '-'),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today_outlined,
                pickup['scheduled_date'] ?? '-'),
            if (pickup['driver_name'] != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.person_outline, pickup['driver_name']),
            ],
            if (pickup['driver_vehicle'] != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.local_shipping_outlined,
                  pickup['driver_vehicle']),
            ],
            if (!isDone) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
        ],
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
            Icon(Icons.local_shipping_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No pickups pending approval',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
}
