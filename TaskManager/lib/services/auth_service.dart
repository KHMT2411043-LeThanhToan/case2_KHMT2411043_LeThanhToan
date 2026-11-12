
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.request(
      method: 'POST',
      path: '/auth/register',
      authenticated: false,
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      },
    );

    final data = _apiClient.decodeMap(response.body);

    if (response.statusCode == 201) {
      await _saveToken(data);
      return data;
    }

    throw Exception(
      data['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.',
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.request(
      method: 'POST',
      path: '/auth/login',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = _apiClient.decodeMap(response.body);

    if (response.statusCode == 200) {
      await _saveToken(data);
      return data;
    }

    throw Exception(
      data['message'] ?? 'Đăng nhập thất bại. Vui lòng thử lại.',
    );
  }

  Future<void> _saveToken(Map<String, dynamic> data) async {
    final token = data['token'];

    if (token is String && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
  }

  Future<String?> getToken() async {
    return _apiClient.getToken();
  }

  Future<String?> getCurrentUserId() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final payloadString = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final payload = jsonDecode(payloadString);

      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final userId = payload['userId'] ??
          payload['id'] ??
          payload['_id'] ??
          payload['sub'];

      return userId?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
