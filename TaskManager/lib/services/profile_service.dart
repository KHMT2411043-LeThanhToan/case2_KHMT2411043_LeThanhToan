
import '../models/user.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  // Lấy thông tin cá nhân.
  Future<User> getProfile() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/profile',
    );

    final data = _apiClient.decodeMap(response.body);

    if (response.statusCode == 200) {
      return User.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải thông tin cá nhân.',
      ),
    );
  }

  // Cập nhật họ tên.
  Future<User> updateFullName(String fullName) async {
    final response = await _apiClient.request(
      method: 'PUT',
      path: '/profile',
      body: {
        'fullName': fullName.trim(),
      },
    );

    final data = _apiClient.decodeMap(response.body);

    if (response.statusCode == 200) {
      return User.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể cập nhật thông tin cá nhân.',
      ),
    );
  }

  // Đổi mật khẩu.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.request(
      method: 'PUT',
      path: '/profile/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể đổi mật khẩu.',
      ),
    );
  }
}
