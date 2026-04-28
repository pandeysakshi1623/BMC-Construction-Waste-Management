import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pickup_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import '../utils/app_theme.dart';
import 'status_chip.dart';

class DriverInfoCard extends StatefulWidget {
  final PickupModel pickup;
  const DriverInfoCard({super.key, required this.pickup});

  @override
  State<DriverInfoCard> createState() => _DriverInfoCardState();
}

class _DriverInfoCardState extends State<DriverInfoCard> {
  Map<String, dynamic>? _location;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    // Stop polling once pickup is done — no point tracking a completed driver
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final s = widget.pickup.status;
      if (s == PickupStatus.completed || s == PickupStatus.failed) {
        _timer?.cancel();
        return;
      }
      _fetchLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final driverId = widget.pickup.driverId;
    if (driverId == null || driverId.isEmpty) return;
    try {
      final token = context.read<AuthProvider>().user?.token ?? '';
      final loc = await ApiService.getDriverLocation(driverId, token: token);
      if (mounted) setState(() => _location = loc);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pickup.driverName == null) return const SizedBox.shrink();

    final pickup = widget.pickup;
    final hasLocation = _location != null;
    final lat = hasLocation
        ? (_location!['latitude'] as num).toStringAsFixed(4)
        : null;
    final lng = hasLocation
        ? (_location!['longitude'] as num).toStringAsFixed(4)
        : null;

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spMD),
      padding: const EdgeInsets.all(AppTheme.spMD),
      decoration: BoxDecoration(
        color: AppTheme.contractor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.contractor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: label + live status chip
          Row(children: [
            Icon(Icons.local_shipping_rounded,
                size: 13, color: AppTheme.contractor),
            const SizedBox(width: 6),
            Text('Assigned Driver',
                style: AppTheme.caption.copyWith(
                    color: AppTheme.contractor,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            StatusChip(status: pickup.status.value),
          ]),
          const SizedBox(height: AppTheme.spSM + 2),

          // Driver name + vehicle + call button
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.contractor.withOpacity(0.1),
              child: Icon(Icons.person_rounded,
                  color: AppTheme.contractor, size: 18),
            ),
            const SizedBox(width: AppTheme.spSM + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pickup.driverName!,
                      style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w600)),
                  if (pickup.driverVehicle != null)
                    Text(pickup.driverVehicle!, style: AppTheme.caption),
                ],
              ),
            ),
            if (pickup.driverPhone != null)
              Material(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  onTap: () => CallService.call(context, pickup.driverPhone!),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.phone_rounded,
                        color: AppTheme.success, size: 18),
                  ),
                ),
              ),
          ]),

          // Live location row
          const SizedBox(height: AppTheme.spSM),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spSM + 2, vertical: 6),
            decoration: BoxDecoration(
              color: hasLocation
                  ? Colors.teal.withOpacity(0.07)
                  : Colors.grey.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(
                color: hasLocation
                    ? Colors.teal.withOpacity(0.3)
                    : AppTheme.divider,
              ),
            ),
            child: Row(children: [
              Icon(Icons.location_on_rounded,
                  size: 13,
                  color: hasLocation ? Colors.teal : AppTheme.textHint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  hasLocation
                      ? 'Live: $lat, $lng'
                      : 'Driver location not available',
                  style: AppTheme.caption.copyWith(
                    color: hasLocation ? Colors.teal : AppTheme.textHint,
                    fontWeight: hasLocation
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (hasLocation)
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.teal, shape: BoxShape.circle),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
