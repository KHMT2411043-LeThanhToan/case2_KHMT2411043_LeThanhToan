
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String> requireToken() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập lại.');
    }

    return token;
  }

  Future<http.Response> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await requireToken();
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers);

      case 'POST':
        return http.post(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'PUT':
        return http.put(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'PATCH':
        return http.patch(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'DELETE':
        return http.delete(uri, headers: headers);

      default:
        throw ArgumentError('Phương thức HTTP không được hỗ trợ: $method');
    }
  }

  Map<String, dynamic> decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception('Dữ liệu máy chủ không đúng định dạng.');
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Máy chủ trả về dữ liệu không hợp lệ.');
      }
      rethrow;
    }
  }

  String getErrorMessage(
      http.Response response, {
        String defaultMessage = 'Đã xảy ra lỗi khi kết nối máy chủ.',
      }) {
    if (response.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }

    try {
      final data = decodeMap(response.body);
      return data['message']?.toString() ?? defaultMessage;
    } catch (_) {
      return defaultMessage;
    }
  }
}
