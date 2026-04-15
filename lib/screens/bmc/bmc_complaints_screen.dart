import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class BmcComplaintsScreen extends StatefulWidget {
  const BmcComplaintsScreen({super.key});

  @override
  State<BmcComplaintsScreen> createState() => _BmcComplaintsScreenState();
}

class _BmcComplaintsScreenState extends State<BmcComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
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
      final data = await ApiService.getBmcComplaints(token: token);
      setState(() => _complaints = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'resolved':   return AppTheme.success;
      case 'rejected':   return AppTheme.error;
      case 'underreview':return AppTheme.warning;
      default:           return AppTheme.pending;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':  return Icons.check_circle_rounded;
      case 'rejected':  return Icons.cancel_rounded;
      default:          return Icons.radio_button_unchecked;
    }
  }

  Future<void> _resolveComplaint(
      Map<String, dynamic> complaint, String action) async {
    double? penaltyAmount;

    // If approving and site_id exists, ask for penalty amount
    if (action == 'approve' && complaint['site_id'] != null) {
      penaltyAmount = await _askPenaltyAmount(complaint);
      if (penaltyAmount == null) return; // user cancelled
    }

    final token = context.read<AuthProvider>().user?.token ?? '';
    try {
      final result = await ApiService.resolveComplaint(
        complaint['query_id'] ?? complaint['id'] ?? '',
        action: action,
        reason: action == 'reject' ? 'Complaint rejected by BMC' : null,
        penaltyAmount: penaltyAmount,
        token: token,
      );

      if (mounted) {
        final msg = action == 'approve'
            ? (result['penalty_id'] != null
                ? '✅ Approved & Penalty Issued: ${result["penalty_id"]}'
                : '✅ Complaint approved')
            : '❌ Complaint rejected';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor:
              action == 'approve' ? AppTheme.success : AppTheme.error,
          duration: const Duration(seconds: 3),
        ));
        _load(); // refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<double?> _askPenaltyAmount(Map<String, dynamic> complaint) async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.gavel, color: AppTheme.error),
          SizedBox(width: 8),
          Text('Issue Penalty'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Site: ${complaint['site_id'] ?? 'Unknown'}',
              style: AppTheme.caption,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Penalty Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter 0 to approve without penalty',
              style: AppTheme.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              Navigator.pop(context, val ?? 0.0);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Citizen Complaints'),
        backgroundColor: AppTheme.bmc,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _complaints.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spMD),
                        itemCount: _complaints.length,
                        itemBuilder: (_, i) => _ComplaintCard(
                          complaint: _complaints[i],
                          statusColor: _statusColor,
                          statusIcon: _statusIcon,
                          onResolve: _resolveComplaint,
                        ),
                      ),
                    ),
    );
  }
}

// ── Complaint card ────────────────────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final Future<void> Function(Map<String, dynamic>, String) onResolve;

  const _ComplaintCard({
    required this.complaint,
    required this.statusColor,
    required this.statusIcon,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] ?? 'Pending';
    final isPending = status.toLowerCase() == 'pending';
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spMD),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(
                  complaint['description'] ?? 'No description',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppTheme.spSM),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon(status), size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(status,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: AppTheme.spSM + 2),

            // Info rows
            if (complaint['site_id'] != null)
              _infoRow(Icons.construction_rounded,
                  'Site: ${complaint['site_id']}', AppTheme.info),
            if (complaint['location'] != null)
              _infoRow(Icons.location_on_rounded,
                  complaint['location'], AppTheme.textSecondary),
            if (complaint['citizen_id'] != null)
              _infoRow(Icons.person_outline_rounded,
                  'Citizen: ${complaint['citizen_id']}',
                  AppTheme.textSecondary),
            if (complaint['created_at'] != null)
              _infoRow(Icons.calendar_today_rounded,
                  complaint['created_at'], AppTheme.textSecondary),

            // Action buttons — only for pending complaints
            if (isPending) ...[
              const SizedBox(height: AppTheme.spMD),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.spSM + 2),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onResolve(complaint, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Reject',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: AppTheme.spSM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onResolve(complaint, 'approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Approve',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ]),
            ],

            // Penalty issued label
            if (status.toLowerCase() == 'resolved') ...[
              const SizedBox(height: AppTheme.spSM),
              Row(children: [
                const Icon(Icons.gavel, size: 13, color: AppTheme.success),
                const SizedBox(width: 5),
                Text('Penalty Issued',
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: AppTheme.caption.copyWith(color: color))),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.error)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.report_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No complaints found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ]),
      );
}
