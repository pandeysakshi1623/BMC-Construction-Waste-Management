import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/notification_service.dart';
import '../services/pickup_service.dart';

class PickupProvider extends ChangeNotifier {
  List<PickupModel> _pickups = [];
  bool _loading = false;
  String? _error;
  bool _firstLoad = true;
  String _token = '';

  List<PickupModel> get pickups => _pickups;
  bool get loading => _loading;
  String? get error => _error;

  void setToken(String token) { _token = token; }

  int countByStatus(PickupStatus s) =>
      _pickups.where((p) => p.status == s).length;

  Future<void> loadPickups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pickups = await PickupService.getAssignedPickups(token: _token);

      if (_firstLoad) {
        _firstLoad = false;
        for (final p in _pickups.where((p) => p.status == PickupStatus.pending)) {
          NotificationService.pickupAssigned(p.siteName);
        }
      }
    } catch (e) {
      _error = 'Failed to load pickups';
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

    final old = _pickups[index];
    _pickups[index] = old.copyWith(status: newStatus, notes: notes);
    notifyListeners();

    try {
      final ok = await PickupService.updatePickupStatus(
          pickupId, newStatus.value,
          notes: notes, token: _token);
      if (!ok) {
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
