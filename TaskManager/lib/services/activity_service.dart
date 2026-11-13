
import '../models/task_activity.dart';
import 'api_client.dart';

class ActivityService {
  final ApiClient _apiClient = ApiClient();

  // E4: Lay lich su hoat dong cua cong viec
  Future<List<TaskActivity>> fetchTaskActivities(
      String taskId,
      ) async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/tasks/$taskId/activities',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);
      final activities = data['activities'];

      if (activities is! List) {
        throw Exception('Dữ liệu lịch sử hoạt động không hợp lệ.');
      }

      return activities
          .whereType<Map>()
          .map(
            (item) => TaskActivity.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải lịch sử hoạt động.',
      ),
    );
  }
}
