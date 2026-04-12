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
  bool get isLoggedIn => _user != null && _user!.role.isNotEmpty;
  bool get initialized => _initialized;
  String? get error => _error;

  AuthProvider() {
    _loadFromPrefs();
  }

  /// Restore session on app start
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');
    final token = prefs.getString('user_token');

    if (id != null && email != null && role != null && token != null && role.isNotEmpty) {
      _user = UserModel(id: id, email: email, role: role, token: token);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
    await prefs.setString('user_token', user.token);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.login(email, password);
      _user = UserModel.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
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
      await _saveToPrefs(_user!);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    await _clearPrefs();
    notifyListeners();
  }
}
