import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/pickup_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pickup_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/status_chip.dart';
import '../profile/profile_screen.dart';

class PickupsScreen extends StatefulWidget {
  const PickupsScreen({super.key});

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabs;
  Timer? _locationTimer;
  Timer? _reloadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final provider = context.read<PickupProvider>();
      provider.setToken(token);
      provider.loadPickups();
      _startLocationUpdates();
      // Reload pickups every 10s so summary bar counts stay current
      _reloadTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) context.read<PickupProvider>().loadPickups();
      });
    });
  }

  /// Send GPS every 8 seconds while any pickup is active
  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      final provider = context.read<PickupProvider>();
      final hasActive = provider.pickups.any((p) =>
          p.status == PickupStatus.accepted ||
          p.status == PickupStatus.inProgress ||
          p.status == PickupStatus.arrived);
      if (!hasActive) return;

      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) return;
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        print('SENDING LOCATION: ${pos.latitude}, ${pos.longitude}');
        final auth = context.read<AuthProvider>();
        final driverId = auth.contractorId.isNotEmpty
            ? auth.contractorId
            : auth.user?.email ?? '';
        await ApiService.updateDriverLocation(
          driverId: driverId,
          latitude: pos.latitude,
          longitude: pos.longitude,
          token: auth.user?.token ?? '',
        );
      } catch (e) {
        print('LOCATION SEND ERROR: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PickupProvider>().loadPickups();
      _startLocationUpdates();
    } else if (state == AppLifecycleState.paused) {
      _locationTimer?.cancel();
      _reloadTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    _locationTimer?.cancel();
    _reloadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.driver,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('My Pickups'),
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
      body: Column(
        children: [
          _SummaryBar(),
          TabBar(
            controller: _tabs,
            labelColor: AppTheme.driver,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.driver,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'All'),
            ],
          ),
          Expanded(
            child: Consumer<PickupProvider>(
              builder: (_, provider, __) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  // Handle session expiry
                  if (provider.error!.contains('Session expired') ||
                      provider.error!.contains('401')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await context.read<AuthProvider>().handleUnauthorized();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (_) => false);
                      }
                    });
                  }
                  return _ErrorView(
                      message: provider.error!,
                      onRetry: provider.loadPickups);
                }

                final active = provider.pickups
                    .where((p) =>
                        p.status != PickupStatus.completed &&
                        p.status != PickupStatus.failed)
                    .toList();                final done = provider.pickups
                    .where((p) =>
                        p.status == PickupStatus.completed ||
                        p.status == PickupStatus.failed)
                    .toList();

                return TabBarView(
                  controller: _tabs,
                  children: [
                    _PickupList(pickups: active, onRefresh: provider.loadPickups),
                    _PickupList(pickups: done, onRefresh: provider.loadPickups),
                    _PickupList(
                        pickups: provider.pickups,
                        onRefresh: provider.loadPickups),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary bar at top ──────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PickupProvider>(
      builder: (_, p, __) {
        // Count all meaningful statuses
        final pending    = p.countByStatus(PickupStatus.pending);
        final accepted   = p.countByStatus(PickupStatus.accepted);
        final inProgress = p.countByStatus(PickupStatus.inProgress);
        final arrived    = p.countByStatus(PickupStatus.arrived);
        final completed  = p.countByStatus(PickupStatus.completed);
        final failed     = p.countByStatus(PickupStatus.failed);
        // Active = accepted + inProgress + arrived
        final active = accepted + inProgress + arrived;

        return Container(
          color: AppTheme.driver,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _badge('Pending',    pending,    Colors.white),
              _vDivider(),
              _badge('Active',     active,     Colors.white),
              _vDivider(),
              _badge('Completed',  completed,  Colors.white),
              _vDivider(),
              _badge('Failed',     failed,     Colors.white70),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String label, int count, Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.85), fontSize: 10)),
        ],
      );

  Widget _vDivider() => Container(
      width: 1, height: 32,
      color: Colors.white.withOpacity(0.25));
}

// ── List wrapper ─────────────────────────────────────────────────────────────
class _PickupList extends StatelessWidget {
  final List<PickupModel> pickups;
  final Future<void> Function() onRefresh;

  const _PickupList({required this.pickups, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (pickups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Nothing here',
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pickups.length,
        itemBuilder: (_, i) => _PickupCard(pickup: pickups[i]),
      ),
    );
  }
}

// ── Individual pickup card ────────────────────────────────────────────────────
class _PickupCard extends StatelessWidget {
  final PickupModel pickup;
  const _PickupCard({required this.pickup});

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(pickup.siteName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                StatusChip(status: pickup.status.value),
              ],
            ),
            const SizedBox(height: 10),
            _row(Icons.location_on_outlined, pickup.location.isNotEmpty ? pickup.location : 'N/A'),
            const SizedBox(height: 4),
            _row(Icons.calendar_today_outlined, _formatDate(pickup.scheduledDate)),
            const SizedBox(height: 4),
            _row(Icons.delete_outline, pickup.wasteType),
            if (pickup.notes != null && pickup.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _row(Icons.notes, pickup.notes!),
            ],
            const Divider(height: 20),
            // Workflow buttons
            _WorkflowButtons(pickup: pickup),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
        ],
      );
}

// ── Workflow action buttons ───────────────────────────────────────────────────
class _WorkflowButtons extends StatefulWidget {
  final PickupModel pickup;
  const _WorkflowButtons({required this.pickup});

  @override
  State<_WorkflowButtons> createState() => _WorkflowButtonsState();
}

class _WorkflowButtonsState extends State<_WorkflowButtons> {
  bool _busy = false;

  Future<void> _transition(PickupStatus next, {String? notes}) async {
    setState(() => _busy = true);
    final ok = await context
        .read<PickupProvider>()
        .updateStatus(widget.pickup.id, next, notes: notes);
    if (mounted) {
      setState(() => _busy = false);
      if (ok) {
        // Use NotificationService for key status transitions
        if (next == PickupStatus.completed) {
          NotificationService.pickupCompleted(widget.pickup.siteName);
        } else if (next == PickupStatus.failed) {
          NotificationService.pickupFailed(widget.pickup.siteName);
        } else {
          // Minor transitions (accepted, inProgress) — simple snackbar
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Status updated to ${next.value}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }
    }
  }

  void _showProofDialog(String proofUrl) {
    final fullUrl = proofUrl.startsWith('http')
        ? proofUrl
        : '${ApiService.base}$proofUrl';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppBar(
            title: const Text('Disposal Proof'),
            backgroundColor: AppTheme.driver,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Image.network(
            fullUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Could not load image'),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<String?> _askFailureReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reason for Failure'),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Describe what went wrong...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }

    final status = widget.pickup.status;

    // Completed / Failed — show read-only badge
    if (status == PickupStatus.completed || status == PickupStatus.failed) {
      return Row(
        children: [
          Icon(
            status == PickupStatus.completed ? Icons.check_circle : Icons.cancel,
            color: status == PickupStatus.completed ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            status == PickupStatus.completed ? 'Pickup completed' : 'Pickup failed',
            style: TextStyle(
              color: status == PickupStatus.completed ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // View proof if available, else allow upload
          if (status == PickupStatus.completed)
            widget.pickup.disposalProofUrl != null
                ? OutlinedButton.icon(
                    onPressed: () => _showProofDialog(widget.pickup.disposalProofUrl!),
                    icon: const Icon(Icons.image_outlined, size: 14),
                    label: const Text('View Proof', style: TextStyle(fontSize: 12)),
                  )
                : OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, '/driver/upload-disposal',
                        arguments: widget.pickup),
                    icon: const Icon(Icons.upload, size: 14),
                    label: const Text('Upload Proof', style: TextStyle(fontSize: 12)),
                  ),
        ],
      );
    }

    // Pending → Accept
    if (status == PickupStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _transition(PickupStatus.accepted),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12)),
          icon: const Icon(Icons.thumb_up_outlined),
          label: const Text('Accept Pickup'),
        ),
      );
    }

    // Accepted → Start + Scan QR
    if (status == PickupStatus.accepted) {
      return Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, '/driver/qr-scanner',
                arguments: widget.pickup),
            icon: const Icon(Icons.qr_code_scanner, size: 16),
            label: const Text('Scan QR'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _transition(PickupStatus.inProgress),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
          ),
        ),
      ]);
    }

    // In Progress → Reached Location or Fail
    if (status == PickupStatus.inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _transition(PickupStatus.arrived),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.location_on),
            label: const Text('Reached Location'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final reason = await _askFailureReason();
              if (reason != null) {
                _transition(PickupStatus.failed, notes: reason);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Mark as Failed'),
          ),
        ],
      );
    }

    // Arrived → Upload proof first, then complete
    if (status == PickupStatus.arrived) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.withOpacity(0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.location_on, color: Colors.teal, size: 16),
              SizedBox(width: 6),
              Text('At site — upload proof to complete',
                  style: TextStyle(color: Colors.teal, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          // Upload proof is mandatory — this navigates to upload screen
          // which marks completed after successful upload
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context, '/driver/upload-disposal',
                arguments: widget.pickup,
              );
              // If upload returned true, mark as completed
              if (result == true && context.mounted) {
                _transition(PickupStatus.completed);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Proof & Complete'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final reason = await _askFailureReason();
              if (reason != null) {
                _transition(PickupStatus.failed, notes: reason);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Mark as Failed'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
