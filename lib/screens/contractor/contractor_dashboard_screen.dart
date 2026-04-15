import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/status_chip.dart';
import 'proof_history_screen.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});
  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState
    extends State<ContractorDashboardScreen> {
  List<SiteModel> _sites = [];
  Map<String, PickupModel> _pickupBySiteId = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final results = await Future.wait([
        ApiService.getContractorSites(token: token),
        ApiService.getContractorPickups(token: token),
      ]);
      final sites = (results[0] as List<Map<String, dynamic>>)
          .map(SiteModel.fromJson).toList();
      final map = <String, PickupModel>{};
      for (final p in results[1] as List<Map<String, dynamic>>) {
        final pickup = PickupModel.fromJson(p);
        map[pickup.siteId] = pickup;
      }
      setState(() { _sites = sites; _pickupBySiteId = map; });
    } catch (e) {
      if (e.toString().contains('401')) {
        await context.read<AuthProvider>().handleUnauthorized();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
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
    return AppScaffold(
      title: 'My Sites',
      extraActions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Alerts',
          onPressed: () => Navigator.pushNamed(context, '/contractor/alerts'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/contractor/register-site');
          _load();
        },
        backgroundColor: AppTheme.contractor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Site',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sites.isEmpty
              ? _EmptyState(onAdd: () async {
                  await Navigator.pushNamed(
                      context, '/contractor/register-site');
                  _load();
                })
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.spMD, AppTheme.spMD,
                        AppTheme.spMD, 100),
                    itemCount: _sites.length,
                    itemBuilder: (_, i) => _SiteCard(
                      site: _sites[i],
                      pickup: _pickupBySiteId[_sites[i].id],
                    ),
                  ),
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
                StatusChip(status: site.pickupStatus),
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
                      arguments: site)),
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
