import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: json['role'] as String,
  );
}

Map<String, dynamic> _userJson(dynamic data) {
  final map = Map<String, dynamic>.from(data as Map);
  if (map['user'] is Map) return Map<String, dynamic>.from(map['user'] as Map);
  if (map['data'] is Map) return Map<String, dynamic>.from(map['data'] as Map);
  return map;
}

class AuthProvider extends ChangeNotifier {
  final _api = ApiClient.instance;

  AuthUser? user;
  bool loading = false;
  bool restoring = true;
  String? error;

  bool get isLoggedIn => user != null;

  Future<void> restore() async {
    try {
      final token = await _api.readToken();
      if (token != null) {
        final res = await _api.dio.get('/me');
        user = AuthUser.fromJson(_userJson(res.data));
      }
    } catch (_) {
      await _api.clearToken();
      user = null;
    }
    restoring = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _authenticate('/login', {'email': email, 'password': password});

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String role,
  }) => _authenticate('/register', {
    'name': name,
    'email': email,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
    'password': password,
    'password_confirmation': password,
    'role': role,
  });

  Future<void> logout() async {
    try {
      await _api.dio.post('/logout');
    } catch (_) {
      // Token dibersihkan di perangkat meskipun server tidak terjangkau.
    }
    await _api.clearToken();
    user = null;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<bool> _authenticate(String path, Map<String, dynamic> body) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _api.dio.post(path, data: body);
      final data = Map<String, dynamic>.from(res.data as Map);
      await _api.saveToken(data['token'] as String);
      user = AuthUser.fromJson(_userJson(data));
      return true;
    } catch (e) {
      error = apiErrorMessage(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
