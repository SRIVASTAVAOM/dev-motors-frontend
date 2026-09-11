import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal();

  static const String baseUrl = 'https://dev-motors-backend.onrender.com/api';

  String? _token;
  Map<String, dynamic>? _user;
  String? _error;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // Convenient getters for UI widgets
  String? get role => _user?['role']?.toString().toUpperCase();
  String? get userRole => _user?['role']?.toString().toUpperCase();
  String? get employeeId => _user?['employeeId']?.toString();
  String? get name => _user?['name']?.toString();
  String? get locationName => _user?['location']?['name']?.toString();

  Future<bool> login(String employeeId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['data']?['token'];
        _user = data['data']?['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Invalid credentials. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to reach server. Please check internet connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();
  }
}
