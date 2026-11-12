
import 'dart:convert';

import 'api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  // Tìm kiếm người dùng theo tên hoặc email.
  Future<List<Map<String, dynamic>>> searchUsers(
      String keyword,
      ) async {
    final query = Uri(
      queryParameters: {
        'q': keyword.trim(),
      },
    ).query;

    final response = await _apiClient.request(
      method: 'GET',
      path: '/users/search?$query',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }

      throw Exception('Dữ liệu người dùng không hợp lệ.');
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tìm kiếm người dùng.',
      ),
    );
  }
}
