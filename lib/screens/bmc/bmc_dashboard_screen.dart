import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final data = await ApiService.getBmcDashboard(token: token);
      setState(() => _dashboardData = data);
    } catch (e) {
      // Dashboard stats are optional — show tiles even if stats fail
      setState(() => _error = null);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('BMC Dashboard'),
        backgroundColor: const Color(0xFF1A237E), // deep indigo for BMC
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Alerts',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BmcAlertsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats row (if available)
                  if (_dashboardData != null) _StatsRow(data: _dashboardData!),
                  if (_dashboardData != null) const SizedBox(height: 20),

                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Action tiles grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _DashboardTile(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan Site QR',
                        color: const Color(0xFF1565C0),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BmcQrScannerScreen())),
                      ),
                      _DashboardTile(
                        icon: Icons.local_shipping,
                        label: 'Truck Approvals',
                        color: const Color(0xFF2E7D32),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const BmcTruckApprovalScreen())),
                      ),
                      _DashboardTile(
                        icon: Icons.report_problem_outlined,
                        label: 'Citizen Complaints',
                        color: const Color(0xFFE65100),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const BmcComplaintsScreen())),
                      ),
                      _DashboardTile(
                        icon: Icons.notifications_active_outlined,
                        label: 'Alerts',
                        color: const Color(0xFFC62828),
                        onTap: () => Navigator.push(
                            context,
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

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Total Sites',
          value: '${data['total_sites'] ?? '-'}',
          icon: Icons.construction,
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Pickups',
          value: '${data['total_pickups'] ?? '-'}',
          icon: Icons.local_shipping,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Penalties',
          value: '${data['total_penalties'] ?? '-'}',
          icon: Icons.gavel,
          color: Colors.red,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard tile ────────────────────────────────────────────────────────────
class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
