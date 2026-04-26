import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { contractor, citizen, driver, official }

extension AppRoleExt on AppRole {
  String get name {
    switch (this) {
      case AppRole.contractor: return 'contractor';
      case AppRole.citizen:    return 'citizen';
      case AppRole.driver:     return 'driver';
      case AppRole.official:   return 'official';
    }
  }

  String get label {
    switch (this) {
      case AppRole.contractor: return 'Contractor';
      case AppRole.citizen:    return 'Citizen';
      case AppRole.driver:     return 'Driver';
      case AppRole.official:   return 'Official';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.contractor: return Icons.engineering;
      case AppRole.citizen:    return Icons.person;
      case AppRole.driver:     return Icons.local_shipping;
      case AppRole.official:   return Icons.admin_panel_settings;
    }
  }

  Color get color {
    switch (this) {
      case AppRole.contractor: return Colors.blue;
      case AppRole.citizen:    return Colors.green;
      case AppRole.driver:     return Colors.deepOrange;
      case AppRole.official:   return Colors.purple;
    }
  }

  String get homeRoute {
    switch (this) {
      case AppRole.contractor: return '/contractor/dashboard';
      case AppRole.citizen:    return '/citizen/complaints';
      case AppRole.driver:     return '/driver/pickups';
      case AppRole.official:   return '/officials/dashboard';
    }
  }

  static AppRole fromString(String value) {
    switch (value) {
      case 'citizen': return AppRole.citizen;
      case 'driver':  return AppRole.driver;
      case 'official':return AppRole.official;
      default:        return AppRole.contractor;
    }
  }
}

class RoleProvider extends ChangeNotifier {
  AppRole _currentRole = AppRole.contractor;
  bool _initialized = false;

  AppRole get currentRole => _currentRole;
  bool get initialized => _initialized;

  RoleProvider() {
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('current_role');
    if (saved != null) {
      _currentRole = AppRoleExt.fromString(saved);
    }
    _initialized = true;
    notifyListeners();
  }

  /// Switch role without logging out — persists the choice
  Future<void> switchRole(AppRole role) async {
    _currentRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_role', role.name);
    notifyListeners();
  }
}
