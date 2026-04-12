import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/call_service.dart';
import '../utils/app_theme.dart';
import 'status_chip.dart';

class DriverInfoCard extends StatelessWidget {
  final PickupModel pickup;
  const DriverInfoCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    if (pickup.driverName == null) return const SizedBox.shrink();

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
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                  onTap: () =>
                      CallService.call(context, pickup.driverPhone!),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.phone_rounded,
                        color: AppTheme.success, size: 18),
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}
