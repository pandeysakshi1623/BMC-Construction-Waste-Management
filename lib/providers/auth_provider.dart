import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _user!.token.isNotEmpty;
  bool get initialized => _initialized;
  String? get error => _error;
  String get role => _user?.role ?? '';

  AuthProvider() {
    _loadFromPrefs();
  }

  /// Restore session on app start
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final email = prefs.getString('user_email');
    final role = prefs.getString('role'); // canonical key

    if (token != null && token.isNotEmpty && email != null) {
      _user = UserModel(
        id: '',
        email: email,
        role: role ?? '',
        token: token,
      );
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Returns the home route based on role from backend
  String _homeRouteForRole(String role) {
    switch (role) {
      case 'contractor': return '/contractor/dashboard';
      case 'driver':     return '/driver/pickups';
      case 'citizen':    return '/citizen/complaints';
      case 'bmc':        return '/bmc/dashboard';
      default:           return '/role-selection'; // fallback
    }
  }

  /// Login — calls role-specific endpoint, forces correct role in prefs, returns home route
  Future<String?> login(String username, String password, {String role = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> data;
      String resolvedRole;

      if (role == 'driver') {
        // Driver uses same endpoint as contractor — force role on frontend
        data = await ApiService.login(username, password);
        resolvedRole = 'driver'; // always override regardless of backend response

      } else if (role == 'bmc') {
        // BMC endpoint does not return role field — force it
        data = await ApiService.loginBmc(username, password);
        resolvedRole = 'bmc'; // always override

      } else if (role == 'citizen') {
        data = await ApiService.loginCitizen(username, password);
        // Use backend role if returned, else fall back to selected
        final backendRole = (data['role'] as String?) ?? '';
        resolvedRole = backendRole.isNotEmpty ? backendRole : 'citizen';

      } else {
        // contractor (default)
        data = await ApiService.login(username, password);
        // Use backend role if returned, else fall back to selected
        final backendRole = (data['role'] as String?) ?? '';
        resolvedRole = backendRole.isNotEmpty ? backendRole : role;
      }

      final token = data['access_token'] as String;

      _user = UserModel(id: '', email: username, role: resolvedRole, token: token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_email', username);
      await prefs.setString('role', resolvedRole); // single canonical key

      print('Logged in as: $resolvedRole'); // debug

      _isLoading = false;
      notifyListeners();
      return _homeRouteForRole(resolvedRole);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> setRole(String role) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        email: _user!.email,
        role: role,
        token: _user!.token,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', role); // canonical key
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    await _clearPrefs();
    notifyListeners();
  }

  /// Call this when any API returns 401 — clears session and forces re-login
  Future<void> handleUnauthorized() async {
    _user = null;
    await _clearPrefs();
    notifyListeners();
  }
}
