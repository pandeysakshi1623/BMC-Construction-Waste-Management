import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../providers/pickup_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/status_chip.dart';

class PickupsScreen extends StatefulWidget {
  const PickupsScreen({super.key});

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PickupProvider>().loadPickups();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Pickups',
      body: Column(
        children: [
          _SummaryBar(),
          TabBar(
            controller: _tabs,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
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
                  return _ErrorView(
                      message: provider.error!,
                      onRetry: provider.loadPickups);
                }

                final active = provider.pickups
                    .where((p) =>
                        p.status != PickupStatus.completed &&
                        p.status != PickupStatus.failed)
                    .toList();
                final done = provider.pickups
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
      builder: (_, p, __) => Container(
        color: Colors.deepOrange,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _badge('Pending',
                p.countByStatus(PickupStatus.pending), Colors.white),
            _badge('In Progress',
                p.countByStatus(PickupStatus.inProgress), Colors.white),
            _badge('Completed',
                p.countByStatus(PickupStatus.completed), Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, int count, Color color) => Column(
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.85), fontSize: 11)),
        ],
      );
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
            _row(Icons.location_on_outlined, pickup.location),
            const SizedBox(height: 4),
            _row(Icons.calendar_today_outlined, pickup.scheduledDate),
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
            status == PickupStatus.completed
                ? Icons.check_circle
                : Icons.cancel,
            color: status == PickupStatus.completed
                ? Colors.green
                : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            status == PickupStatus.completed
                ? 'Pickup completed'
                : 'Pickup failed',
            style: TextStyle(
              color: status == PickupStatus.completed
                  ? Colors.green
                  : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (status == PickupStatus.completed)
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                  context, '/driver/upload-disposal',
                  arguments: widget.pickup),
              icon: const Icon(Icons.upload, size: 14),
              label: const Text('Proof', style: TextStyle(fontSize: 12)),
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

    // In Progress → Complete or Fail
    if (status == PickupStatus.inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _transition(PickupStatus.completed),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Completed'),
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
