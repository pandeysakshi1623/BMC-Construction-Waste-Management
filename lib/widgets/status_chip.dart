import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'completed':
      case 'resolved':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'inprogress':
        return Colors.indigo;
      case 'scheduled':
        return Colors.teal;
      case 'underreview':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'completed':
      case 'resolved':
        return Icons.check_circle;
      case 'accepted':
        return Icons.thumb_up;
      case 'inprogress':
        return Icons.directions_car;
      case 'scheduled':
        return Icons.schedule;
      case 'underreview':
        return Icons.hourglass_top;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
