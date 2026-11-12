import 'dart:convert';

import '../models/task.dart';
import 'api_client.dart';
import 'task_share_service.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();
  final TaskShareService _taskShareService = TaskShareService();

  Future<List<Task>> fetchTasks({String? type}) async {
    final query = type == null
        ? ''
        : '?${Uri(queryParameters: {'type': type}).query}';

    final response = await _apiClient.request(
      method: 'GET',
      path: '/tasks$query',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is! List) {
        throw Exception('Dữ liệu danh sách công việc không hợp lệ.');
      }

      return data
          .map((item) => Task.fromJson(
        Map<String, dynamic>.from(item as Map),
      ))
          .toList();
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage:
        'Không thể tải danh sách công việc: ${response.statusCode}',
      ),
    );
  }

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
    final response = await _apiClient.request(
      method: 'POST',
      path: '/tasks',
      body: {
        'title': title,
        'description': description,
        'priority': priority,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'assignedTo': assignedTo,
        'primaryAssigneeId': primaryAssigneeId,
        'sharedWith': sharedWith,
        'sharedPermissions': sharedPermissions,
      },
    );

    if (response.statusCode == 201) {
      final data = _apiClient.decodeMap(response.body);

      return Task.fromJson(
        data['task'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tạo công việc.',
      ),
    );
  }

  Future<Task> updateTask({
    required String taskId,
    required String title,
    required String description,
    String? status,
    String? priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final Map<String, dynamic> requestData = {
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };

    if (status != null) {
      requestData['status'] = status;
    }

    if (priority != null) {
      requestData['priority'] = priority;
    }

    final response = await _apiClient.request(
      method: 'PUT',
      path: '/tasks/$taskId',
      body: requestData,
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);

      return Task.fromJson(
        data['task'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể cập nhật công việc.',
      ),
    );
  }

  // Cập nhật danh sách người được giao và người phụ trách chính.
  Future<Task> updateTaskAssignments({
    required String taskId,
    required List<String> assignedTo,
    String? primaryAssigneeId,
  }) async {
    final response = await _apiClient.request(
      method: 'PUT',
      path: '/assignments/$taskId',
      body: {
        'assignedTo': assignedTo,
        'primaryAssigneeId': primaryAssigneeId,
      },
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);

      return Task.fromJson(
        data['task'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể cập nhật người được giao.',
      ),
    );
  }

  Future<void> deleteTask({
    required String taskId,
  }) async {
    final response = await _apiClient.request(
      method: 'DELETE',
      path: '/tasks/$taskId',
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể xóa công việc.',
      ),
    );
  }

  Future<void> addSharedUser({
    required String taskId,
    required String userId,
    String permission = 'viewer',
  }) {
    return _taskShareService.addSharedUser(
      taskId: taskId,
      userId: userId,
      permission: permission,
    );
  }

  Future<void> updateSharePermission({
    required String taskId,
    required String userId,
    required String permission,
  }) {
    return _taskShareService.updateSharePermission(
      taskId: taskId,
      userId: userId,
      permission: permission,
    );
  }

  Future<void> revokeSharePermission({
    required String taskId,
    required String userId,
  }) {
    return _taskShareService.revokeSharePermission(
      taskId: taskId,
      userId: userId,
    );
  }

  Future<void> updateMyProgress({
    required String taskId,
    required String status,
  }) async {
    final response = await _apiClient.request(
      method: 'PUT',
      path: '/tasks/$taskId/progress',
      body: {
        'status': status,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể cập nhật tiến độ.',
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchEmailLogs({
    required String taskId,
  }) async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/tasks/$taskId/email-logs',
    );

    final data = _apiClient.decodeMap(response.body);

    if (response.statusCode == 200) {
      final logs = data['emailLogs'] ?? [];

      if (logs is! List) {
        throw Exception('Dữ liệu lịch sử email không hợp lệ.');
      }

      return logs
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể lấy lịch sử gửi email.',
      ),
    );
  }
}