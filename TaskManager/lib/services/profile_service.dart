
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/profile';

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200) {
      return data['user'] as Map<String, dynamic>;
    }

    throw Exception(
      data['message'] ?? 'Không thể tải thông tin cá nhân.',
    );
  }

  Future<Map<String, dynamic>> updateFullName(String fullName) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullName': fullName.trim(),
      }),
    );

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200) {
      return data['user'] as Map<String, dynamic>;
    }

    throw Exception(
      data['message'] ?? 'Không thể cập nhật thông tin cá nhân.',
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Bạn chưa đăng nhập. Vui lòng đăng nhập lại.');
    }

    return token;
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Máy chủ trả về dữ liệu không hợp lệ.');
    }
  }
}
