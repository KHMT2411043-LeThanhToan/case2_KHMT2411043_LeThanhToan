
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class UserService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/users';

  final AuthService _authService = AuthService();

  // Tim kiem nguoi dung theo ten hoac email
  Future<List<Map<String, dynamic>>> searchUsers(
      String keyword,
      ) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': keyword.trim(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception('Du lieu nguoi dung khong hop le.');
    }

    if (response.statusCode == 401) {
      throw Exception('Phien dang nhap het han. Vui long dang nhap lai.');
    }

    final data = jsonDecode(response.body);

    throw Exception(
      data is Map
          ? data['message'] ?? 'Khong the tim kiem nguoi dung.'
          : 'Khong the tim kiem nguoi dung.',
    );
  }
}
