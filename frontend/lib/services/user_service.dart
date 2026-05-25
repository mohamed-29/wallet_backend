import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserData {
  final String id;
  final String name;
  final String phone;
  final String email;
  final double walletBalance;
  final String tier;
  final String avatarInitial;

  const UserData({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.walletBalance,
    required this.tier,
    required this.avatarInitial,
  });

  factory UserData.fromJson(Map<String, dynamic> json, {double balance = 0.0}) {
    final name = json['first_name'] != null && (json['first_name'] as String).isNotEmpty
        ? json['first_name']
        : (json['username'] ?? 'User');
    return UserData(
      id: json['id'].toString(),
      name: name,
      phone: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      walletBalance: balance,
      tier: 'Standard',
      avatarInitial: (name as String)[0].toUpperCase(),
    );
  }
}

class UserService {
  static const String baseUrl = 'https://fridge.ivend.cloud/api/v1';
  static const _storage = FlutterSecureStorage();
  static String? _token;
  static String? _refreshToken;
  static bool _isFirstTime = true;

  static String? get token => _token;
  static bool get isFirstTimeFlag => _isFirstTime;

  static Future<void> init() async {
    _token = await _storage.read(key: 'auth_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    final firstTimeStr = await _storage.read(key: 'is_first_time');
    _isFirstTime = firstTimeStr == null;
  }

  static Future<void> setNotFirstTime() async {
    _isFirstTime = false;
    await _storage.write(key: 'is_first_time', value: 'false');
  }

  /// Try to refresh the access token using the refresh token.
  /// Returns true if successful.
  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        if (data['refresh'] != null) {
          _refreshToken = data['refresh'];
          await _storage.write(key: 'refresh_token', value: _refreshToken);
        }
        await _storage.write(key: 'auth_token', value: _token);
        debugPrint('Token refreshed successfully');
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }
    return false;
  }

  /// Make an authenticated GET request with auto token refresh on 401.
  static Future<http.Response> authGet(String path) async {
    var response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.get(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
      }
    }
    return response;
  }

  /// Make an authenticated POST request with auto token refresh on 401.
  static Future<http.Response> authPost(String path, Map<String, dynamic> body) async {
    var response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await http.post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: jsonEncode(body),
        );
      }
    }
    return response;
  }

  static Future<bool> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        _refreshToken = data['refresh'];
        await _storage.write(key: 'auth_token', value: _token);
        if (_refreshToken != null) {
          await _storage.write(key: 'refresh_token', value: _refreshToken);
        }
        await setNotFirstTime();
        return true;
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    }
    return false;
  }

  static Future<bool> register(String name, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone_number': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        _refreshToken = data['refresh'];
        await _storage.write(key: 'auth_token', value: _token);
        if (_refreshToken != null) {
          await _storage.write(key: 'refresh_token', value: _refreshToken);
        }
        await setNotFirstTime();
        return true;
      }
    } catch (e) {
      debugPrint('Register Error: $e');
    }
    return false;
  }

  /// Update the signed-in user's personal info (name and/or email).
  /// Returns null on success, or an error message string on failure.
  static Future<String?> updateProfile({String? name, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      final response = await authPost('/auth/update-profile/', body);
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      final err = data['error'];
      if (err is List && err.isNotEmpty) return err.join(' ');
      if (err is String) return err;
      return 'Could not update profile. Please try again.';
    } catch (e) {
      debugPrint('Update profile error: $e');
      return 'Network error. Please try again.';
    }
  }

  /// Change the signed-in user's password. Requires the current password.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await authPost('/auth/change-password/', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      final err = data['error'];
      if (err is List && err.isNotEmpty) return err.join(' ');
      if (err is String) return err;
      return 'Could not change password. Please try again.';
    } catch (e) {
      debugPrint('Change password error: $e');
      return 'Network error. Please try again.';
    }
  }

  static Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<UserData> fetch() async {
    if (_token == null) throw Exception('Not authenticated');

    final balanceRes = await authGet('/wallet/balance/');
    final userRes = await authGet('/users/');

    if (balanceRes.statusCode == 200 && userRes.statusCode == 200) {
      final balanceData = jsonDecode(balanceRes.body);
      final userDataList = jsonDecode(userRes.body);
      final userData = userDataList[0];

      return UserData.fromJson(
        userData,
        balance: (balanceData['balance_cents'] / 100).toDouble()
      );
    } else {
      throw Exception('Failed to load user data');
    }
  }

  /// Fetch only the wallet balance (lighter call for post-payment refresh).
  static Future<double?> fetchBalance() async {
    if (_token == null) return null;
    try {
      final res = await authGet('/wallet/balance/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['balance_cents'] / 100).toDouble();
      }
    } catch (e) {
      debugPrint('Balance fetch error: $e');
    }
    return null;
  }
}
