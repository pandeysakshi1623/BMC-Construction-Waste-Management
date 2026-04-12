import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { contractor, citizen, driver }

extension AppRoleExt on AppRole {
  String get name {
    switch (this) {
      case AppRole.contractor: return 'contractor';
      case AppRole.citizen:    return 'citizen';
      case AppRole.driver:     return 'driver';
    }
  }

  String get label {
    switch (this) {
      case AppRole.contractor: return 'Contractor';
      case AppRole.citizen:    return 'Citizen';
      case AppRole.driver:     return 'Driver';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.contractor: return Icons.engineering;
      case AppRole.citizen:    return Icons.person;
      case AppRole.driver:     return Icons.local_shipping;
    }
  }

  Color get color {
    switch (this) {
      case AppRole.contractor: return Colors.blue;
      case AppRole.citizen:    return Colors.green;
      case AppRole.driver:     return Colors.deepOrange;
    }
  }

  String get homeRoute {
    switch (this) {
      case AppRole.contractor: return '/contractor/dashboard';
      case AppRole.citizen:    return '/citizen/complaints';
      case AppRole.driver:     return '/driver/pickups';
    }
  }

  static AppRole fromString(String value) {
    switch (value) {
      case 'citizen': return AppRole.citizen;
      case 'driver':  return AppRole.driver;
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
