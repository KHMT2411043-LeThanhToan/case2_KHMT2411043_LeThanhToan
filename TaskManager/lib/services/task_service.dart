
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
    List<String> assignedTo = const [],
    String? primaryAssigneeId,
    List<String> sharedWith = const [],
    List<Map<String, String>> sharedPermissions = const [],
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
        'assignedTo': assignedTo,
        'primaryAssigneeId': primaryAssigneeId,
        'sharedWith': sharedWith,
        'sharedPermissions': sharedPermissions,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      return Task.fromJson(data['task'] as Map<String, dynamic>);
    }

    final Map<String, dynamic> errorData = jsonDecode(response.body);

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

    final Map<String, dynamic> errorData = jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the xoa cong viec.',
    );
  }

  // Moi nguoi moi chia se cong viec
  Future<void> addSharedUser({
    required String taskId,
    required String userId,
    String permission = 'viewer',
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/shares'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'permission': permission,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return;
    }

    throw Exception(
      data['message'] ?? 'Khong the moi nguoi chia se cong viec.',
    );
  }

  // Thay doi quyen chia se cong viec
  Future<void> updateSharePermission({
    required String taskId,
    required String userId,
    required String permission,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/$taskId/shares/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'permission': permission,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    final Map<String, dynamic> errorData = jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the thay doi quyen chia se.',
    );
  }

  // Thu hoi quyen chia se cong viec
  Future<void> revokeSharePermission({
    required String taskId,
    required String userId,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId/shares/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    final Map<String, dynamic> errorData = jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the thu hoi quyen chia se.',
    );
  }

  // Cap nhat tien do ca nhan
  Future<void> updateMyProgress({
    required String taskId,
    required String status,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/$taskId/progress'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    final Map<String, dynamic> errorData = jsonDecode(response.body);

    throw Exception(
      errorData['message'] ?? 'Khong the cap nhat tien do.',
    );
  }
  // D6: Lay lich su gui email cua cong viec
  Future<List<Map<String, dynamic>>> fetchEmailLogs({
    required String taskId,
  }) async {
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui long dang nhap lai.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$taskId/email-logs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> logs = data['emailLogs'] ?? [];

      return logs
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }

    throw Exception(
      data['message'] ?? 'Khong the lay lich su gui email.',
    );
  }
}
