
import '../models/deadline_statistics.dart';
import 'api_client.dart';

class DeadlineService {
  final ApiClient _apiClient = ApiClient();

  Future<DeadlineStatistics> fetchDeadlineTasks() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/deadlines',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);

      return DeadlineStatistics.fromJson(data);
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage:
        'Không thể tải danh sách công việc sắp đến hạn và quá hạn.',
      ),
    );
  }
}
