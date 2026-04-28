import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../profile/profile_screen.dart';
import 'bmc_qr_scanner_screen.dart';
import 'bmc_truck_approval_screen.dart';
import 'bmc_complaints_screen.dart';
import 'bmc_alerts_screen.dart';

class BmcDashboardScreen extends StatefulWidget {
  const BmcDashboardScreen({super.key});
  @override
  State<BmcDashboardScreen> createState() => _BmcDashboardScreenState();
}

class _BmcDashboardScreenState extends State<BmcDashboardScreen> {
  int _navIndex = 0;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentComplaints = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh every 10 seconds so new complaints appear quickly
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final results = await Future.wait([
        ApiService.getBmcDashboard(token: token),
        ApiService.getBmcComplaints(token: token),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          final all = results[1] as List<Map<String, dynamic>>;
          // Show only recent 5 pending complaints on dashboard
          _recentComplaints = all
              .where((c) => (c['status'] ?? 'Pending').toLowerCase() == 'pending')
              .take(5)
              .toList();
        });
      }
    } catch (_) {
      // Silent fail — stats are optional
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardHome(
        stats: _stats,
        loading: _loading,
        recentComplaints: _recentComplaints,
        onRefresh: _load,
      ),
      // Key forces BmcComplaintsScreen to re-init (and re-fetch) each time
      // the tab is selected, so new complaints appear immediately.
      BmcComplaintsScreen(key: ValueKey('complaints_$_navIndex')),
      const BmcTruckApprovalScreen(),
      const BmcAlertsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bmc,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Icon(Icons.account_balance_rounded, size: 20),
          const SizedBox(width: 8),
          Text(_navTitles[_navIndex]),
        ]),
        actions: [
          // Live indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.greenAccent, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Live',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: pages[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          // Reload data whenever user taps Dashboard or Complaints tab
          if (i == 0 || i == 1) _load();
        },
        indicatorColor: AppTheme.bmc.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.bmc),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: _recentComplaints.isNotEmpty,
                label: Text('${_recentComplaints.length}'),
                child: const Icon(Icons.report_outlined),
              ),
              selectedIcon: const Icon(Icons.report, color: AppTheme.bmc),
              label: 'Complaints'),
          const NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon:
                  Icon(Icons.local_shipping, color: AppTheme.bmc),
              label: 'Trucks'),
          const NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon:
                  Icon(Icons.notifications, color: AppTheme.bmc),
              label: 'Alerts'),
        ],
      ),
    );
  }

  static const _navTitles = [
    'BMC Dashboard',
    'Citizen Complaints',
    'Truck Approvals',
    'Alerts',
  ];
}

// ── Dashboard home tab ────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool loading;
  final List<Map<String, dynamic>> recentComplaints;
  final Future<void> Function() onRefresh;

  const _DashboardHome({
    required this.stats,
    required this.loading,
    required this.recentComplaints,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spMD),
        children: [
          // Welcome banner
          _WelcomeBanner(),
          AppTheme.gapMD,

          // Stats row
          if (stats != null) ...[
            _StatsGrid(stats: stats!),
            AppTheme.gapLG,
          ],

          // Quick actions
          Text('Quick Actions', style: AppTheme.heading3),
          AppTheme.gapMD,
          _QuickActions(),
          AppTheme.gapLG,

          // Pending complaints preview
          if (recentComplaints.isNotEmpty) ...[
            Row(children: [
              Text('Pending Complaints', style: AppTheme.heading3),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ]),
            AppTheme.gapSM,
            ...recentComplaints.map((c) => _MiniComplaintCard(complaint: c)),
          ],
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.bmc, Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting, BMC Official',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
            AppTheme.gapXS,
            const Text('Construction Waste Monitor',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            AppTheme.gapXS,
            Text('Last updated: ${_now()}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        const Icon(Icons.account_balance_rounded,
            color: Colors.white24, size: 48),
      ]),
    );
  }

  String _now() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Total Sites', '${stats['total_sites'] ?? 0}',
          Icons.construction_rounded, AppTheme.info),
      _StatItem('Pickups', '${stats['total_pickups'] ?? 0}',
          Icons.local_shipping_rounded, AppTheme.success),
      _StatItem('Penalties', '${stats['total_penalties'] ?? 0}',
          Icons.gavel_rounded, AppTheme.error),
      _StatItem('Complaints', '${stats['total_complaints'] ?? 0}',
          Icons.report_rounded, AppTheme.warning),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppTheme.spSM,
      mainAxisSpacing: AppTheme.spSM,
      childAspectRatio: 1.6,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: item.color.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        const SizedBox(width: AppTheme.spSM + 2),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: item.color)),
          Text(item.label, style: AppTheme.caption),
        ]),
      ]),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.qr_code_scanner_rounded, 'Scan QR', AppTheme.info,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BmcQrScannerScreen()))),
      _Action(Icons.report_problem_rounded, 'Complaints', AppTheme.driver,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BmcComplaintsScreen()))),
      _Action(Icons.local_shipping_rounded, 'Trucks', AppTheme.success,
          () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const BmcTruckApprovalScreen()))),
      _Action(Icons.notifications_active_rounded, 'Alerts', AppTheme.error,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BmcAlertsScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppTheme.spSM,
      mainAxisSpacing: AppTheme.spSM,
      childAspectRatio: 0.85,
      children: actions.map((a) => _ActionTile(action: a)).toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
}

class _ActionTile extends StatelessWidget {
  final _Action action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(action.label,
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MiniComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  const _MiniComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spSM),
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.report_outlined,
              color: AppTheme.warning, size: 16),
        ),
        const SizedBox(width: AppTheme.spSM + 2),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              complaint['description'] ?? 'No description',
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (complaint['site_id'] != null)
              Text('Site: ${complaint['site_id']}', style: AppTheme.caption),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: const Text('Pending',
              style: TextStyle(
                  color: AppTheme.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
