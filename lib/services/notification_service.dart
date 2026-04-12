import 'package:flutter/material.dart';

/// Centralized notification service.
/// Currently uses SnackBar. Replace body of each method with
/// flutter_local_notifications calls when ready for production.
class NotificationService {
  static final _key = GlobalKey<ScaffoldMessengerState>();

  /// Attach this key to MaterialApp.scaffoldMessengerKey
  static GlobalKey<ScaffoldMessengerState> get messengerKey => _key;

  static void _show(String message, {Color color = Colors.black87, IconData icon = Icons.notifications}) {
    _key.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Citizen: complaint status changed
  static void complaintResolved(String description) {
    _show(
      'Your complaint "$description" has been resolved.',
      color: Colors.green[700]!,
      icon: Icons.check_circle,
    );
  }

  /// Driver: new pickup assigned
  static void pickupAssigned(String siteName) {
    _show(
      'New pickup assigned: $siteName',
      color: Colors.blue[700]!,
      icon: Icons.local_shipping,
    );
  }

  /// Contractor: pickup completed by driver
  static void pickupCompleted(String siteName) {
    _show(
      'Pickup completed for site: $siteName',
      color: Colors.green[700]!,
      icon: Icons.check_circle_outline,
    );
  }

  /// Contractor: pickup failed
  static void pickupFailed(String siteName) {
    _show(
      'Pickup failed for site: $siteName. Please reschedule.',
      color: Colors.red[700]!,
      icon: Icons.warning_amber_rounded,
    );
  }
}
