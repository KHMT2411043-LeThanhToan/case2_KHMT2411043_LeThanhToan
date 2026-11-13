import '../models/statistics.dart';
import '../models/assignment_statistics.dart';
import 'api_client.dart';

class StatisticsService {
  final ApiClient _apiClient = ApiClient();

  // E1: Thống kê công việc theo trạng thái
  Future<Statistics> fetchTaskStatisticsByStatus() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/statistics/tasks-by-status',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);

      return Statistics.fromJson(data);
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải thống kê công việc.',
      ),
    );
  }

  // E2: Thống kê công việc được giao và phụ trách chính
  Future<AssignmentStatistics> fetchAssignmentStatistics() async {
    final response = await _apiClient.request(
      method: 'GET',
      path: '/statistics/assignments',
    );

    if (response.statusCode == 200) {
      final data = _apiClient.decodeMap(response.body);

      return AssignmentStatistics.fromJson(data);
    }

    throw Exception(
      _apiClient.getErrorMessage(
        response,
        defaultMessage: 'Không thể tải thống kê phân công.',
      ),
    );
  }
}