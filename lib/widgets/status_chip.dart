import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'completed':
      case 'resolved':   return AppTheme.success;
      case 'accepted':   return AppTheme.info;
      case 'inprogress': return const Color(0xFF3949AB);
      case 'arrived':    return Colors.teal;
      case 'scheduled':  return const Color(0xFF00838F);
      case 'underreview':return AppTheme.warning;
      case 'failed':     return AppTheme.error;
      default:           return AppTheme.pending;
    }
  }

  IconData get _icon {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'completed':
      case 'resolved':   return Icons.check_circle_rounded;
      case 'accepted':   return Icons.thumb_up_rounded;
      case 'inprogress': return Icons.local_shipping_rounded;
      case 'arrived':    return Icons.location_on_rounded;
      case 'scheduled':  return Icons.schedule_rounded;
      case 'underreview':return Icons.hourglass_top_rounded;
      case 'failed':     return Icons.cancel_rounded;
      default:           return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spSM + 2, vertical: AppTheme.spXS),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, size: 11, color: _color),
        const SizedBox(width: 4),
        Text(status,
            style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2)),
      ]),
    );
  }
}
