
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import 'auth_service.dart';

class TaskService {
  static const String baseUrl =
      'http://10.0.2.2:5000/api/tasks';

  // Lay danh sach cong viec
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

  // Tao cong viec
  Future<Task> createTask({
    required String title,
    String description = '',
    String priority = 'medium',
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      return Task.fromJson(data['task'] as Map<String, dynamic>);
    }

    final Map<String, dynamic> errorData =
    jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the tao cong viec.',
    );
  }

  // Chinh sua cong viec va cap nhat trang thai, muc do uu tien
  Future<Task> updateTask({
    required String taskId,
    required String title,
    required String description,
    String? status,
    String? priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final Map<String, dynamic> requestData = {
      'title': title,
      'description': description,
    };

    if (status != null) {
      requestData['status'] = status;
    }

    if (priority != null) {
      requestData['priority'] = priority;
    }
    requestData['startDate'] = startDate?.toIso8601String();
    requestData['dueDate'] = dueDate?.toIso8601String();
    final response = await http.put(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      return Task.fromJson(data['task'] as Map<String, dynamic>);
    }

    final Map<String, dynamic> errorData = jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the cap nhat cong viec.',
    );
  }

  // Xoa cong viec
  Future<void> deleteTask({
    required String taskId,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    final Map<String, dynamic> errorData =
    jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the xoa cong viec.',
    );
  }
}
