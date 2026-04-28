import 'dart:io';
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
  String get contractorId => _user?.contractorId ?? '';

  AuthProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final email = prefs.getString('user_email');
    final role = prefs.getString('role');
    final contractorId = prefs.getString('contractor_id') ?? '';
    if (token != null && token.isNotEmpty && email != null) {
      _user = UserModel(
        id: '',
        email: email,
        role: role ?? '',
        token: token,
        contractorId: contractorId,
      );
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String _homeRouteForRole(String role) {
    switch (role) {
      case 'contractor': return '/contractor/dashboard';
      case 'driver':     return '/driver/pickups';
      case 'citizen':    return '/citizen/complaints';
      case 'bmc':        return '/bmc/dashboard';
      default:           return '/role-selection';
    }
  }

  Future<String?> login(String username, String password, {String role = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> data;
      String resolvedRole;
      String contractorId = '';

      if (role == 'bmc') {
        data = await ApiService.loginBmc(username, password);
        resolvedRole = 'bmc';
      } else if (role == 'citizen') {
        data = await ApiService.loginCitizen(username, password);
        final backendRole = (data['role'] as String?) ?? '';
        resolvedRole = backendRole.isNotEmpty ? backendRole : 'citizen';
      } else {
        data = await ApiService.login(username, password);
        final backendRole = (data['role'] as String?) ?? '';
        resolvedRole = backendRole.isNotEmpty ? backendRole : role;
        contractorId = (data['contractor_id'] as String?) ?? '';
      }

      final token = data['access_token'] as String;
      _user = UserModel(
        id: '',
        email: username,
        role: resolvedRole,
        token: token,
        contractorId: contractorId,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_email', username);
      await prefs.setString('role', resolvedRole);
      if (contractorId.isNotEmpty) {
        await prefs.setString('contractor_id', contractorId);
      }

      _isLoading = false;
      notifyListeners();
      return _homeRouteForRole(resolvedRole);
    } catch (e) {
      if (e is SocketException) {
        _error = 'Cannot reach server. Make sure the backend is running.';
      } else {
        _error = e.toString().replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    await _clearPrefs();
    notifyListeners();
  }

  Future<void> handleUnauthorized() async {
    _user = null;
    await _clearPrefs();
    notifyListeners();
  }
}

