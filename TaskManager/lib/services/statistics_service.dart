
import '../models/statistics.dart';
import '../models/assignment_statistics.dart';
import 'api_client.dart';

class StatisticsService {
  final ApiClient _apiClient = ApiClient();

  // E1: Thong ke cong viec theo trang thai
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

  // E2: Thong ke cong viec duoc giao va phu trach
  Future<AssignmentStatistics> fetchAssignmentStatistics() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/statistics/assignments',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);
      final statistics = data['statistics'];

      if (statistics is! Map) {
        throw Exception('Dữ liệu thống kê phân công không hợp lệ.');
      }

      return AssignmentStatistics.fromJson(
        Map<String, dynamic>.from(statistics),
      );
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải thống kê công việc được giao.',
      ),
    );
  }
}
