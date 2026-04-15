import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/status_chip.dart';
import 'citizen_qr_scanner_screen.dart';
import 'report_complaint_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  final Set<String> _notified = {};
  int _selectedIndex = 0; // bottom nav index

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getComplaints(token: token);
      final loaded = data.map(ComplaintModel.fromJson).toList();
      for (final c in loaded) {
        if (c.status.toLowerCase() == 'resolved' && !_notified.contains(c.id)) {
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

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReportOptionsSheet(
        onScanQr: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CitizenQrScannerScreen()))
              .then((_) => _load());
        },
        onManualReport: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const ReportComplaintScreen(
                      siteId: '', siteName: 'Manual Report')))
              .then((_) => _load());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.citizen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.eco_rounded),
            tooltip: 'Awareness',
            onPressed: () => Navigator.pushNamed(context, '/citizen/awareness'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/citizen/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (ok == true && mounted) {
                await auth.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? _EmptyState(onReport: _showReportOptions)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.spMD, AppTheme.spMD, AppTheme.spMD, 100),
                    itemCount: _complaints.length,
                    itemBuilder: (_, i) => _ComplaintTile(complaint: _complaints[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportOptions,
        backgroundColor: AppTheme.citizen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Report Issue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          if (i == 1) Navigator.pushNamed(context, '/citizen/awareness');
        },
        indicatorColor: AppTheme.citizen.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.report_outlined),
              selectedIcon: Icon(Icons.report, color: AppTheme.citizen),
              label: 'Complaints'),
          NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              selectedIcon: Icon(Icons.eco, color: AppTheme.citizen),
              label: 'Awareness'),
        ],
      ),
    );
  }
}

// ── Report options bottom sheet ───────────────────────────────────────────────
class _ReportOptionsSheet extends StatelessWidget {
  final VoidCallback onScanQr;
  final VoidCallback onManualReport;
  const _ReportOptionsSheet({required this.onScanQr, required this.onManualReport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spLG),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          AppTheme.gapMD,
          Text('How would you like to report?', style: AppTheme.heading3),
          AppTheme.gapSM,
          Text('Choose a method to submit your complaint',
              style: AppTheme.caption),
          AppTheme.gapLG,

          // Scan QR option
          _OptionTile(
            icon: Icons.qr_code_scanner_rounded,
            color: AppTheme.citizen,
            title: 'Scan Site QR Code',
            subtitle: 'Scan the QR at the construction site — auto-fills site details',
            badge: 'Recommended',
            onTap: onScanQr,
          ),
          AppTheme.gapSM,

          // Manual report option
          _OptionTile(
            icon: Icons.edit_note_rounded,
            color: AppTheme.info,
            title: 'Report Manually',
            subtitle: 'Enter site details manually if QR is not available',
            onTap: onManualReport,
          ),
          AppTheme.gapMD,
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spMD),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.spMD),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              AppTheme.gapXS,
              Text(subtitle, style: AppTheme.caption),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReport;
  const _EmptyState({required this.onReport});

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
          Text('Tap "Report Issue" to submit a complaint', style: AppTheme.caption),
          AppTheme.gapLG,
          ElevatedButton.icon(
            onPressed: onReport,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.citizen, foregroundColor: Colors.white),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Report Issue'),
          ),
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
