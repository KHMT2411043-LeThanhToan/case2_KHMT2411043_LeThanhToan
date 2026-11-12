


import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  // Lấy danh sách thông báo
  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/notifications',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);
      final notifications = data['notifications'];

      if (notifications is! List) {
        throw Exception('Dữ liệu thông báo không hợp lệ.');
      }

      return notifications
          .whereType<Map<String, dynamic>>()
          .map((item) => AppNotification.fromJson(item))
          .toList();
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải danh sách thông báo.',
      ),
    );
  }

  // Lấy số thông báo chưa đọc
  Future<int> fetchUnreadCount() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/notifications/unread-count',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải số thông báo chưa đọc.',
      ),
    );
  }

  // Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    final response = await _apiClient.request(
      method: 'PATCH',
      path: '/notifications/$notificationId/read',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _apiClient.getErrorMessage(
          response,
          defaultMessage: 'Không thể đánh dấu thông báo đã đọc.',
        ),
      );
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead() async {
    final response = await _apiClient.request(
      method: 'PATCH',
      path: '/notifications/read-all',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _apiClient.getErrorMessage(
          response,
          defaultMessage: 'Không thể đánh dấu tất cả thông báo đã đọc.',
        ),
      );
    }
  }
}
