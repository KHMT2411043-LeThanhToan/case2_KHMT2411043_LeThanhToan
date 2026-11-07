
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/auth';

  // Dang ky tai khoan
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/register');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    final Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('May chu tra ve du lieu khong hop le.');
    }

    if (response.statusCode == 201) {
      await _saveToken(data);
      return data;
    }

    throw Exception(
      data['message'] ?? 'Dang ky that bai. Vui long thu lai.',
    );
  }

  // Dang nhap
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/login');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('May chu tra ve du lieu khong hop le.');
    }

    if (response.statusCode == 200) {
      await _saveToken(data);
      return data;
    }

    throw Exception(
      data['message'] ?? 'Dang nhap that bai. Vui long thu lai.',
    );
  }

  // Luu token dang nhap
  Future<void> _saveToken(Map<String, dynamic> data) async {
    final token = data['token'];

    if (token is String && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
  }

  // Lay token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Lay ID nguoi dung hien tai tu JWT
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

      final userId =
          payload['userId'] ??
              payload['id'] ??
              payload['_id'] ??
              payload['sub'];

      return userId?.toString();
    } catch (_) {
      return null;
    }
  }

  // Dang xuat
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
