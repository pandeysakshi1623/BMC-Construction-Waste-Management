import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/status_chip.dart';
import '../profile/profile_screen.dart';
import 'proof_history_screen.dart';
import 'alerts_screen.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});
  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState
    extends State<ContractorDashboardScreen> with WidgetsBindingObserver {
  List<SiteModel> _sites = [];
  Map<String, PickupModel> _pickupBySiteId = {};
  List<Map<String, dynamic>> _penalties = [];
  bool _loading = true;
  int _navIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startTimer();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    // 15s is frequent enough without hammering the server
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadSilent();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSilent();
      _startTimer();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Silent reload — no spinner, used by timer and lifecycle resume
  Future<void> _loadSilent() async {
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.user?.token ?? '';
      final contractorId = auth.contractorId;
      final results = await Future.wait([
        ApiService.getContractorSites(token: token),
        ApiService.getContractorPickups(token: token),
        if (contractorId.isNotEmpty)
          ApiService.getContractorPenalties(contractorId: contractorId, token: token)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);
      final sites = (results[0] as List<Map<String, dynamic>>)
          .map(SiteModel.fromJson).toList();
      final map = <String, PickupModel>{};
      for (final p in results[1] as List<Map<String, dynamic>>) {
        final pickup = PickupModel.fromJson(p);
        map[pickup.siteId] = pickup;
      }
      if (mounted) {
        setState(() {
          _sites = sites;
          _pickupBySiteId = map;
          _penalties = results[2] as List<Map<String, dynamic>>;
        });
      }
    } catch (_) {
      // Silent — don't show error on background refresh
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.user?.token ?? '';
      final contractorId = auth.contractorId;

      final results = await Future.wait([
        ApiService.getContractorSites(token: token),
        ApiService.getContractorPickups(token: token),
        if (contractorId.isNotEmpty)
          ApiService.getContractorPenalties(contractorId: contractorId, token: token)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);
      final sites = (results[0] as List<Map<String, dynamic>>)
          .map(SiteModel.fromJson).toList();
      final map = <String, PickupModel>{};
      for (final p in results[1] as List<Map<String, dynamic>>) {
        final pickup = PickupModel.fromJson(p);
        map[pickup.siteId] = pickup;
      }
      if (mounted) {
        setState(() {
          _sites = sites;
          _pickupBySiteId = map;
          _penalties = results[2] as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      if (e.toString().contains('401')) {
        await context.read<AuthProvider>().handleUnauthorized();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to load sites'),
            backgroundColor: AppTheme.error,
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.contractor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(_navIndex == 0 ? 'My Sites' : _navIndex == 1 ? 'Penalties' : 'Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
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
      body: IndexedStack(
        index: _navIndex,
        children: [
          _SitesTab(
            sites: _sites,
            pickupBySiteId: _pickupBySiteId,
            penalties: _penalties,
            loading: _loading,
            onRefresh: _load,
          ),
          _PenaltiesTab(penalties: _penalties),
          AlertsScreen(role: 'contractor'),
        ],
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, '/contractor/register-site');
                _load();
              },
              backgroundColor: AppTheme.contractor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('New Site',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        indicatorColor: AppTheme.contractor.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.construction_outlined),
              selectedIcon: Icon(Icons.construction, color: AppTheme.contractor),
              label: 'Sites'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: _penalties.isNotEmpty,
                label: Text('${_penalties.length}'),
                child: const Icon(Icons.gavel_outlined),
              ),
              selectedIcon: const Icon(Icons.gavel, color: AppTheme.contractor),
              label: 'Penalties'),
          const NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications, color: AppTheme.contractor),
              label: 'Alerts'),
        ],
      ),
    );
  }
}

// ── Sites tab ─────────────────────────────────────────────────────────────────
class _SitesTab extends StatelessWidget {
  final List<SiteModel> sites;
  final Map<String, PickupModel> pickupBySiteId;
  final List<Map<String, dynamic>> penalties;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _SitesTab({
    required this.sites,
    required this.pickupBySiteId,
    required this.penalties,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (sites.isEmpty) {
      return _EmptyState(onAdd: () async {
        await Navigator.pushNamed(context, '/contractor/register-site');
        onRefresh();
      });
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spMD, AppTheme.spMD, AppTheme.spMD, 100),
        children: [
          if (penalties.isNotEmpty) ...[
            _PenaltiesBanner(penalties: penalties),
            AppTheme.gapMD,
          ],
          ...sites.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spMD),
                child: _SiteCard(site: s, pickup: pickupBySiteId[s.id]),
              )),
        ],
      ),
    );
  }
}

// ── Penalties tab ─────────────────────────────────────────────────────────────
class _PenaltiesTab extends StatelessWidget {
  final List<Map<String, dynamic>> penalties;
  const _PenaltiesTab({required this.penalties});

  double get _total => penalties.fold(
      0.0, (s, p) => s + ((p['penalty_cost_rupees'] ?? 0) as num).toDouble());

  @override
  Widget build(BuildContext context) {
    if (penalties.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                size: 48, color: AppTheme.success),
          ),
          AppTheme.gapMD,
          Text('No penalties issued', style: AppTheme.heading3),
          AppTheme.gapSM,
          Text('Your sites are compliant', style: AppTheme.caption),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spMD),
      children: [
        // Total summary card
        Container(
          padding: const EdgeInsets.all(AppTheme.spMD),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.error, AppTheme.error.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(children: [
            const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
            const SizedBox(width: AppTheme.spMD),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Penalties',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('₹${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            Text('${penalties.length} issued',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        AppTheme.gapMD,
        ...penalties.map((p) => _PenaltyCard(penalty: p)),
      ],
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  final Map<String, dynamic> penalty;
  const _PenaltyCard({required this.penalty});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spSM + 2),
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: AppTheme.cardDecoration,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.gavel_rounded,
              color: AppTheme.error, size: 18),
        ),
        const SizedBox(width: AppTheme.spMD),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('₹${penalty['penalty_cost_rupees'] ?? 0}',
                style: AppTheme.heading3.copyWith(color: AppTheme.error)),
            AppTheme.gapXS,
            Text(penalty['reason'] ?? 'No reason provided',
                style: AppTheme.caption, maxLines: 2),
            AppTheme.gapXS,
            Row(children: [
              const Icon(Icons.construction_rounded,
                  size: 11, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(penalty['site_id'] ?? '', style: AppTheme.caption),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today_rounded,
                  size: 11, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text(penalty['date_issued'] ?? '', style: AppTheme.caption),
            ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(penalty['penalty_status'] ?? 'Active',
              style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _PenaltiesBanner extends StatelessWidget {
  final List<Map<String, dynamic>> penalties;
  const _PenaltiesBanner({required this.penalties});

  double get _total => penalties.fold(
      0.0, (sum, p) => sum + ((p['penalty_cost_rupees'] ?? 0) as num).toDouble());

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.gavel_rounded, color: AppTheme.error, size: 18),
            const SizedBox(width: AppTheme.spSM),
            Text('Penalty Issued',
                style: AppTheme.heading3.copyWith(color: AppTheme.error)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text('₹${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ]),
          const SizedBox(height: AppTheme.spSM),
          ...penalties.take(3).map((p) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 6, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p['site_id'] ?? ''}: ₹${p['penalty_cost_rupees'] ?? 0} — ${p['reason'] ?? ''}',
                      style: AppTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              )),
          if (penalties.length > 3) ...[
            const SizedBox(height: 4),
            Text('+${penalties.length - 3} more penalties',
                style: AppTheme.caption.copyWith(color: AppTheme.error)),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.contractor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.construction_rounded,
                size: 48, color: AppTheme.contractor),
          ),
          AppTheme.gapMD,
          Text('No sites yet', style: AppTheme.heading3),
          AppTheme.gapSM,
          Text('Register your first construction site',
              style: AppTheme.caption),
          AppTheme.gapLG,
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.contractor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Register Site'),
          ),
        ]),
      );
}

class _SiteCard extends StatelessWidget {
  final SiteModel site;
  final PickupModel? pickup;
  const _SiteCard({required this.site, this.pickup});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spMD),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(site.name, style: AppTheme.heading3),
                      AppTheme.gapXS,
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppTheme.textHint),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(site.location, style: AppTheme.caption,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      if (site.id.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tag,
                                  size: 11, color: Colors.blue),
                              const SizedBox(width: 3),
                              Text(site.id,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spSM),
                // Use live pickup status if available, else fall back to site's cached status
                StatusChip(status: pickup?.status.value ?? site.pickupStatus),
              ],
            ),
          ),

          // Stats row
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spMD),
            padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spSM + 2),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('Expected', '${site.expectedWaste}t',
                    Icons.inventory_2_outlined),
                _divider(),
                _stat('Actual', '${site.actualWaste}t',
                    Icons.delete_outline_rounded),
                _divider(),
                _stat('Area', '${site.area}m²',
                    Icons.square_foot_rounded),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppTheme.spMD),
            child: Row(children: [
              _actionBtn(context, Icons.qr_code_rounded, 'QR Code',
                  AppTheme.contractor, () => Navigator.pushNamed(
                      context, '/contractor/qr-display',
                      arguments: site)),
              const SizedBox(width: AppTheme.spSM),
              _actionBtn(context, Icons.schedule_rounded, 'Schedule',
                  AppTheme.info, () => Navigator.pushNamed(
                      context, '/contractor/schedule-pickup',
                      arguments: site)),
              const SizedBox(width: AppTheme.spSM),
              _actionBtn(context, Icons.upload_rounded, 'Proof',
                  AppTheme.success, () => Navigator.pushNamed(
                      context, '/contractor/upload-proof',
                      // Pass pickup if available so upload screen can check arrival status
                      arguments: pickup ?? site)),
              const SizedBox(width: AppTheme.spSM),
              _actionBtn(context, Icons.history_rounded, 'History',
                  Colors.purple, () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProofHistoryScreen(site: site)))),
            ]),
          ),

          if (pickup != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spMD, 0, AppTheme.spMD, AppTheme.spMD),
              child: DriverInfoCard(pickup: pickup!),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(height: 3),
          Text(value,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: AppTheme.caption),
        ],
      );

  Widget _divider() => Container(
      height: 32, width: 1, color: AppTheme.divider);

  Widget _actionBtn(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: AppTheme.caption.copyWith(
                    color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
