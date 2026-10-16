import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiService? api}) : _api = api ?? ApiService() {
    _loadToken();
  }

  final ApiService _api;

  String? _token;
  bool _isLoading = false;

  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    notifyListeners();
  }

  /// Signs in and stores the token. An [ApiException] from the server is
  /// rethrown to the caller after [isLoading] has been reset.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _api.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _token = token;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    notifyListeners();
  }

  /// Called by [NotesProvider] when the server rejected the token.
  Future<void> handleUnauthorized() => logout();
}
