import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/notification_service.dart';
import '../services/pickup_service.dart';

class PickupProvider extends ChangeNotifier {
  List<PickupModel> _pickups = [];
  bool _loading = false;
  String? _error;
  bool _firstLoad = true; // guard — notify only on first load

  List<PickupModel> get pickups => _pickups;
  bool get loading => _loading;
  String? get error => _error;

  /// Counts by status — useful for dashboard badges
  int countByStatus(PickupStatus s) =>
      _pickups.where((p) => p.status == s).length;

  Future<void> loadPickups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pickups = await PickupService.getAssignedPickups();

      // Notify driver of pending pickups on first load only
      if (_firstLoad) {
        _firstLoad = false;
        final pending = _pickups
            .where((p) => p.status == PickupStatus.pending)
            .toList();
        for (final pickup in pending) {
          NotificationService.pickupAssigned(pickup.siteName);
        }
      }
    } catch (e) {
      _error = 'Failed to load pickups';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Updates a single pickup's status locally + calls API
  Future<bool> updateStatus(
    String pickupId,
    PickupStatus newStatus, {
    String? notes,
  }) async {
    final index = _pickups.indexWhere((p) => p.id == pickupId);
    if (index == -1) return false;

    // Optimistic update
    final old = _pickups[index];
    _pickups[index] = old.copyWith(status: newStatus, notes: notes);
    notifyListeners();

    try {
      final ok = await PickupService.updatePickupStatus(
          pickupId, newStatus.value, notes: notes);
      if (!ok) {
        // Rollback on failure
        _pickups[index] = old;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      _pickups[index] = old;
      notifyListeners();
      return false;
    }
  }
}
