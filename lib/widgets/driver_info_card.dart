import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/call_service.dart';
import 'status_chip.dart';

/// Shows assigned driver info + live pickup status on contractor dashboard
class DriverInfoCard extends StatelessWidget {
  final PickupModel pickup;

  const DriverInfoCard({super.key, required this.pickup});

  @override
  Widget build(BuildContext context) {
    if (pickup.driverName == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_shipping, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            const Text('Assigned Driver',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const Spacer(),
            StatusChip(status: pickup.status.value),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pickup.driverName!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (pickup.driverVehicle != null)
                      Text(pickup.driverVehicle!,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              if (pickup.driverPhone != null)
                IconButton(
                  onPressed: () =>
                      CallService.call(context, pickup.driverPhone!),
                  icon: const Icon(Icons.phone, color: Colors.green),
                  tooltip: 'Call Driver',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
