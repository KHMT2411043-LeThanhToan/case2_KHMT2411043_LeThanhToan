
import 'api_client.dart';

class TaskShareService {
  final ApiClient _apiClient = ApiClient();

  // Mời người dùng chia sẻ công việc.
  Future<void> addSharedUser({
    required String taskId,
    required String userId,
    String permission = 'viewer',
  }) async {
    final response = await _apiClient.request(
      method: 'POST',
      path: '/tasks/$taskId/shares',
      body: {
        'userId': userId,
        'permission': permission,
      },
    );

    if (response.statusCode == 201) {
      return;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể mời người dùng chia sẻ công việc.',
      ),
    );
  }

  // Thay đổi quyền chia sẻ.
  Future<void> updateSharePermission({
    required String taskId,
    required String userId,
    required String permission,
  }) async {
    final response = await _apiClient.request(
      method: 'PUT',
      path: '/tasks/$taskId/shares/$userId',
      body: {
        'permission': permission,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể thay đổi quyền chia sẻ.',
      ),
    );
  }

  // Thu hồi quyền chia sẻ.
  Future<void> revokeSharePermission({
    required String taskId,
    required String userId,
  }) async {
    final response = await _apiClient.request(
      method: 'DELETE',
      path: '/tasks/$taskId/shares/$userId',
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể thu hồi quyền chia sẻ.',
      ),
    );
  }
}
