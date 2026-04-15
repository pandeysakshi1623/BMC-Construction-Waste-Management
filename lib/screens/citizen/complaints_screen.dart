import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/status_chip.dart';
import 'citizen_qr_scanner_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  final Set<String> _notified = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getComplaints(token: token);
      final loaded = data.map(ComplaintModel.fromJson).toList();
      for (final c in loaded) {
        if (c.status.toLowerCase() == 'resolved' &&
            !_notified.contains(c.id)) {
          _notified.add(c.id);
          NotificationService.complaintResolved(c.description);
        }
      }
      setState(() => _complaints = loaded);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to load complaints'),
          backgroundColor: AppTheme.error,
        ));
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
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scan Site QR',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CitizenQrScannerScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.eco_rounded),
          tooltip: 'Waste Awareness',
          onPressed: () => Navigator.pushNamed(context, '/citizen/awareness'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // QR scan is mandatory entry point — open scanner, not complaint screen
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CitizenQrScannerScreen()),
          );
          _load(); // refresh list after returning
        },
        backgroundColor: AppTheme.citizen,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan & Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.spMD, AppTheme.spMD,
                        AppTheme.spMD, 100),
                    itemCount: _complaints.length,
                    itemBuilder: (_, i) =>
                        _ComplaintTile(complaint: _complaints[i]),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.citizen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.report_gmailerrorred_rounded,
                size: 48, color: AppTheme.citizen),
          ),
          AppTheme.gapMD,
          Text('No complaints yet', style: AppTheme.heading3),
          AppTheme.gapSM,
          Text('Tap + Report to submit a new complaint',
              style: AppTheme.caption),
        ]),
      );
}

class _ComplaintTile extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintTile({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spSM + 2),
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(complaint.description,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppTheme.spSM),
            StatusChip(status: complaint.status),
          ]),
          if (complaint.location.isNotEmpty) ...[
            AppTheme.gapSM,
            _row(Icons.location_on_rounded, complaint.location),
          ],
          if (complaint.createdAt.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spXS),
            _row(Icons.calendar_today_rounded, complaint.createdAt),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: AppTheme.textHint),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: AppTheme.caption)),
      ]);
}
