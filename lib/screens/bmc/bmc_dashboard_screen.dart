import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
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
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getBmcDashboard(token: token);
      setState(() => _stats = data);
    } catch (_) {
      // Stats optional — show tiles even if they fail
    } finally {
      setState(() => _loading = false);
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
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white),
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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bmc,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('BMC Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BmcAlertsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spMD),
                children: [
                  if (_stats != null) ...[
                    _StatsRow(stats: _stats!),
                    AppTheme.gapLG,
                  ],
                  Text('Quick Actions', style: AppTheme.heading3),
                  AppTheme.gapMD,
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppTheme.spMD,
                    mainAxisSpacing: AppTheme.spMD,
                    childAspectRatio: 1.15,
                    children: [
                      _Tile(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan Site QR',
                        color: AppTheme.info,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const BmcQrScannerScreen())),
                      ),
                      _Tile(
                        icon: Icons.local_shipping_rounded,
                        label: 'Truck Approvals',
                        color: AppTheme.success,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const BmcTruckApprovalScreen())),
                      ),
                      _Tile(
                        icon: Icons.report_problem_rounded,
                        label: 'Citizen Complaints',
                        color: AppTheme.driver,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const BmcComplaintsScreen())),
                      ),
                      _Tile(
                        icon: Icons.notifications_active_rounded,
                        label: 'Alerts',
                        color: AppTheme.error,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const BmcAlertsScreen())),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatCard('Sites', '${stats['total_sites'] ?? 0}',
          Icons.construction_rounded, AppTheme.info),
      const SizedBox(width: AppTheme.spSM + 2),
      _StatCard('Pickups', '${stats['total_pickups'] ?? 0}',
          Icons.local_shipping_rounded, AppTheme.success),
      const SizedBox(width: AppTheme.spSM + 2),
      _StatCard('Penalties', '${stats['total_penalties'] ?? 0}',
          Icons.gavel_rounded, AppTheme.error),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spMD, horizontal: AppTheme.spSM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          AppTheme.gapXS,
          Text(value,
              style: AppTheme.heading2.copyWith(color: color, fontSize: 22)),
          Text(label, style: AppTheme.caption, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Tile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spMD),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                AppTheme.gapSM + AppTheme.gapXS,
                Text(label,
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on SizedBox {
  SizedBox operator +(SizedBox other) =>
      SizedBox(height: (height ?? 0) + (other.height ?? 0));
}
