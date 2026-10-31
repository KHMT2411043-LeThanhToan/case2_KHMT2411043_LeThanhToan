
import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/auth';

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
      throw Exception('Máy chủ trả về dữ liệu không hợp lệ.');
    }

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.',
    );
  }
}
