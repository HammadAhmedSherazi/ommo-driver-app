import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ommo/auth/models/user_model.dart';
import 'package:ommo/auth/service/auth_service.dart';
import 'package:ommo/utils/constants/constants.dart';

class ProfileService {
  ProfileService({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<ProfileResult<UserModel>> getProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return ProfileResult.failure('Not authenticated');
      }

      final url = Uri.parse(AppApis.userProfile);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final map = data is Map<String, dynamic> ? data : null;
        if (map != null) {
          return ProfileResult.success(UserModel.fromJson(map));
        }
        return ProfileResult.failure('Invalid response');
      }

      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Failed to load profile').toString()
          : 'Failed to load profile';
      return ProfileResult.failure(message);
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }

  Future<ProfileResult<UserModel>> updateProfile(UserModel user) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        return ProfileResult.failure('Not authenticated');
      }

      final url = Uri.parse(AppApis.userProfileUpdate);
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final map = data is Map<String, dynamic> ? data : null;
        if (map != null) {
          return ProfileResult.success(UserModel.fromJson(map));
        }
        return ProfileResult.success(user);
      }

      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Failed to update profile').toString()
          : 'Failed to update profile';
      return ProfileResult.failure(message);
    } catch (e) {
      return ProfileResult.failure(e.toString());
    }
  }
}

class ProfileResult<T> {
  const ProfileResult._({this.data, this.errorMessage});

  final T? data;
  final String? errorMessage;

  bool get isSuccess => data != null && errorMessage == null;

  factory ProfileResult.success(T data) =>
      ProfileResult._(data: data);
  factory ProfileResult.failure(String message) =>
      ProfileResult._(errorMessage: message);
}
