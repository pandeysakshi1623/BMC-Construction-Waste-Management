import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/status_chip.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  final Map<String, String> _addresses = {};

  // Tracks which complaint IDs were already resolved — prevents re-notifying
  final Set<String> _alreadyNotified = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getComplaints();
      final loaded = data.map((e) => ComplaintModel.fromJson(e)).toList();

      // Fire notification for any newly resolved complaints
      for (final complaint in loaded) {
        if (complaint.status.toLowerCase() == 'resolved' &&
            !_alreadyNotified.contains(complaint.id)) {
          _alreadyNotified.add(complaint.id);
          NotificationService.complaintResolved(complaint.description);
        }
      }

      setState(() => _complaints = loaded);

      // Resolve addresses in background — don't block the list from showing
      for (final complaint in loaded) {
        if (!_addresses.containsKey(complaint.id)) {
          final address = await LocationService.reverseGeocode(
              complaint.latitude, complaint.longitude);
          if (mounted) {
            setState(() => _addresses[complaint.id] = address);
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load complaints'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Complaints',
      extraActions: [
        IconButton(
          icon: const Icon(Icons.eco, color: Colors.white),
          tooltip: 'Waste Awareness',
          onPressed: () =>
              Navigator.pushNamed(context, '/citizen/awareness'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/citizen/report');
          _load();
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Report', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _complaints.length,
                    itemBuilder: (_, i) => _ComplaintCard(
                        complaint: _complaints[i],
                        address: _addresses[_complaints[i].id],
                      ),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No complaints yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + to report an issue',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final String? address;
  const _ComplaintCard({required this.complaint, this.address});

  @override
  Widget build(BuildContext context) {
    final locationText = address ??
        'Lat: ${complaint.latitude.toStringAsFixed(4)}, Lng: ${complaint.longitude.toStringAsFixed(4)}';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(complaint.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                const SizedBox(width: 8),
                StatusChip(status: complaint.status),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on, locationText),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today, complaint.createdAt),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
        ],
      );
}
