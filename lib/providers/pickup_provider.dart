import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/notification_service.dart';
import '../services/pickup_service.dart';

class PickupProvider extends ChangeNotifier {
  List<PickupModel> _pickups = [];
  bool _loading = false;
  String? _error;
  String _token = '';

  // Track IDs already notified so we don't re-notify on every reload
  final Set<String> _notifiedIds = {};

  List<PickupModel> get pickups => _pickups;
  bool get loading => _loading;
  String? get error => _error;

  void setToken(String token) {
    _token = token;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  int countByStatus(PickupStatus s) =>
      _pickups.where((p) => p.status == s).length;

  Future<void> loadPickups() async {
    // Don't show spinner on background reloads if we already have data
    if (_pickups.isEmpty) {
      _loading = true;
      notifyListeners();
    }
    _error = null;

    try {
      final fresh = await PickupService.getAssignedPickups(token: _token);

      // Notify only for newly pending pickups not seen before
      for (final p in fresh.where((p) => p.status == PickupStatus.pending)) {
        if (!_notifiedIds.contains(p.id)) {
          _notifiedIds.add(p.id);
          NotificationService.pickupAssigned(p.siteName);
        }
      }

      _pickups = fresh;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Only set error if we have no cached data — otherwise fail silently
      if (_pickups.isEmpty) {
        _error = msg;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
        pickupId,
        newStatus.value,
        notes: notes,
        token: _token,
      );
      if (!ok) {
        _pickups[index] = old; // revert
        notifyListeners();
      }
      return ok;
    } catch (_) {
      _pickups[index] = old; // revert
      notifyListeners();
      return false;
    }
  }
}
