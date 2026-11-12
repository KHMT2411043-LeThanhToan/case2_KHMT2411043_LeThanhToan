
import '../models/statistics.dart';
import 'api_client.dart';

class StatisticsService {
  final ApiClient _apiClient = ApiClient();

  Future<Statistics> fetchTaskStatisticsByStatus() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/statistics/tasks-by-status',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);
      final statistics = data['statistics'];

      if (statistics is! Map) {
        throw Exception('Dữ liệu thống kê không hợp lệ.');
      }

      return Statistics.fromJson(
        Map<String, dynamic>.from(statistics),
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải thống kê công việc.',
      ),
    );
  }
}
