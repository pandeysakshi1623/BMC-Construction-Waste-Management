import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../models/site_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/status_chip.dart';

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
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';

      // Load both in parallel
      final results = await Future.wait([
        ApiService.getContractorSites(token: token),
        ApiService.getContractorPickups(token: token),
      ]);

      final sites = (results[0] as List<Map<String, dynamic>>)
          .map((e) => SiteModel.fromJson(e))
          .toList();

      final pickupMap = <String, PickupModel>{};
      for (final p in results[1] as List<Map<String, dynamic>>) {
        final pickup = PickupModel.fromJson(p);
        pickupMap[pickup.siteId] = pickup;
      }

      setState(() {
        _sites = sites;
        _pickupBySiteId = pickupMap;
      });
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        if (mounted) {
          await context.read<AuthProvider>().handleUnauthorized();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      } else {
        _showSnack('Failed to load data', isError: true);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // keep _loadSites as alias so FAB still works
  Future<void> _loadSites() => _loadData();

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Contractor Dashboard',
      extraActions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          tooltip: 'Alerts',
          onPressed: () =>
              Navigator.pushNamed(context, '/contractor/alerts'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/contractor/register-site');
          _loadSites();
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Site', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sites.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadSites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sites.length,
                    itemBuilder: (_, i) => _SiteCard(
                      site: _sites[i],
                      pickup: _pickupBySiteId[_sites[i].id],
                      onRefresh: _loadSites,
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No sites registered yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + to register your first site',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
}

class _SiteCard extends StatelessWidget {
  final SiteModel site;
  final PickupModel? pickup;
  final VoidCallback onRefresh;

  const _SiteCard({required this.site, required this.onRefresh, this.pickup});

  @override
  Widget build(BuildContext context) {
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
                  child: Text(site.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                StatusChip(status: site.pickupStatus),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(site.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            ]),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Expected', '${site.expectedWaste}t'),
                _stat('Actual', '${site.actualWaste}t'),
                _stat('Area', '${site.area}m²'),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              _actionBtn(context, Icons.qr_code, 'QR',
                  () => Navigator.pushNamed(context, '/contractor/qr-display',
                      arguments: site)),
              const SizedBox(width: 8),
              _actionBtn(context, Icons.schedule, 'Schedule',
                  () => Navigator.pushNamed(
                      context, '/contractor/schedule-pickup',
                      arguments: site)),
              const SizedBox(width: 8),
              _actionBtn(context, Icons.upload, 'Proof',
                  () => Navigator.pushNamed(
                      context, '/contractor/upload-proof',
                      arguments: site)),
            ]),
            if (pickup != null) DriverInfoCard(pickup: pickup!),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      );

  Widget _actionBtn(
          BuildContext context, IconData icon, String label, VoidCallback onTap) =>
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 15),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
}
