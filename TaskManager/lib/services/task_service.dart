
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import 'auth_service.dart';

class TaskService {
  static const String baseUrl =
      'http://10.0.2.2:5000/api/tasks';

  Future<List<Task>> fetchTasks({String? type}) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: type == null ? null : {'type': type},
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Khong the tai danh sach cong viec: ${response.statusCode}',
    );
  }
}
