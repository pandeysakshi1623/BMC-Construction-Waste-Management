import 'package:flutter/material.dart';

enum AppRole { contractor, citizen, driver, bmc }

extension AppRoleExt on AppRole {
  String get name {
    switch (this) {
      case AppRole.contractor: return 'contractor';
      case AppRole.citizen:    return 'citizen';
      case AppRole.driver:     return 'driver';
      case AppRole.bmc:        return 'bmc';
    }
  }

  String get label {
    switch (this) {
      case AppRole.contractor: return 'Contractor';
      case AppRole.citizen:    return 'Citizen';
      case AppRole.driver:     return 'Driver';
      case AppRole.bmc:        return 'BMC Official';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.contractor: return Icons.engineering;
      case AppRole.citizen:    return Icons.person;
      case AppRole.driver:     return Icons.local_shipping;
      case AppRole.bmc:        return Icons.account_balance;
    }
  }

  Color get color {
    switch (this) {
      case AppRole.contractor: return const Color(0xFF1565C0);
      case AppRole.citizen:    return const Color(0xFF2E7D32);
      case AppRole.driver:     return const Color(0xFFE65100);
      case AppRole.bmc:        return const Color(0xFF1A237E);
    }
  }

  String get homeRoute {
    switch (this) {
      case AppRole.contractor: return '/contractor/dashboard';
      case AppRole.citizen:    return '/citizen/complaints';
      case AppRole.driver:     return '/driver/pickups';
      case AppRole.bmc:        return '/bmc/dashboard';
    }
  }

  static AppRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'citizen':    return AppRole.citizen;
      case 'driver':     return AppRole.driver;
      case 'bmc':        return AppRole.bmc;
      default:           return AppRole.contractor;
    }
  }
}

/// Derives the current role directly from AuthProvider's stored role string.
/// This is the single source of truth — no separate SharedPreferences key.
class RoleProvider extends ChangeNotifier {
  AppRole _currentRole = AppRole.contractor;

  AppRole get currentRole => _currentRole;

  /// Call this after login or session restore to sync the role badge.
  void syncFromAuthRole(String roleString) {
    final parsed = AppRoleExt.fromString(roleString);
    if (parsed != _currentRole) {
      _currentRole = parsed;
      notifyListeners();
    }
  }
}
