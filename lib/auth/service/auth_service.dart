import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/helpers/local_storage.dart';

class AuthService {
  AuthService({LocalStorage? storage})
      : _storage = storage ?? LocalStorage();

  static const String _tokenKey = 'auth_token';

  final LocalStorage _storage;

  Future<String?> getToken() async {
    final value = await _storage.readValue(_tokenKey);
    return value is String ? value : null;
  }

  Future<void> setToken(String token) async {
    await _storage.setValue(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _storage.clearValue(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(AppApis.login);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>?;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = data?['token'] as String? ??
            data?['access_token'] as String? ??
            data?['accessToken'] as String?;
        if (token != null && token.isNotEmpty) {
          await setToken(token);
          return AuthResult.success();
        }
        return AuthResult.success();
      }

      final message = data?['message'] as String? ??
          data?['error'] as String? ??
          'Login failed';
      return AuthResult.failure(message.toString());
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String employmentType,
    required String cdlLicenseNumber,
    required String licenseState,
  }) async {
    try {
      final url = Uri.parse(AppApis.register);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_Name': firstName,
          'last_Name': lastName,
          'email': email,
          'password': password,
          'phone': phone,
          'employment_Type': employmentType,
          'cdl_License_Number': cdlLicenseNumber,
          'license_State': licenseState,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>?;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = data?['token'] as String? ??
            data?['access_token'] as String? ??
            data?['accessToken'] as String?;
        if (token != null && token.isNotEmpty) {
          await setToken(token);
        }
        return AuthResult.success();
      }

      final message = data?['message'] as String? ??
          data?['error'] as String? ??
          'Registration failed';
      return AuthResult.failure(message.toString());
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<void> logout() async {
    await clearToken();
  }
}

class AuthResult {
  const AuthResult._({this.success = false, this.errorMessage});

  final bool success;
  final String? errorMessage;

  factory AuthResult.success() => const AuthResult._(success: true);
  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, errorMessage: message);
}
