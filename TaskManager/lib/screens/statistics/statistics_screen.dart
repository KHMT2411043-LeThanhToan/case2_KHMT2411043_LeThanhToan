
import 'package:flutter/material.dart';

import '../../models/statistics.dart';
import '../../models/assignment_statistics.dart';
import '../../services/statistics_service.dart';
import 'deadline_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();

  late Future<Statistics> _statisticsFuture;
  late Future<AssignmentStatistics> _assignmentStatisticsFuture;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    _statisticsFuture =
        _statisticsService.fetchTaskStatisticsByStatus();

    _assignmentStatisticsFuture =
        _statisticsService.fetchAssignmentStatistics();
  }

  Future<void> _reloadStatistics() async {
    setState(() {
      _loadStatistics();
    });

    try {
      await Future.wait<void>([
        _statisticsFuture.then<void>((_) {}),
        _assignmentStatisticsFuture.then<void>((_) {}),
      ]);
    } catch (_) {
      // Loi duoc hien thi rieng trong cac FutureBuilder.
    }
  }

  void _openDeadlineScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeadlineScreen(),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 36,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // E1: Thong ke cong viec theo trang thai
  Widget _buildStatusStatistics() {
    return FutureBuilder<Statistics>(
      future: _statisticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildError(
            message:
            'Không thể tải thống kê theo trạng thái.\n${snapshot.error}',
            onRetry: _reloadStatistics,
          );
        }

        final statistics = snapshot.data;

        if (statistics == null) {
          return const Text('Không có dữ liệu thống kê.');
        }

        return Column(
          children: [
            _buildStatisticCard(
              title: 'Tổng số công việc',
              count: statistics.total,
              icon: Icons.assignment_outlined,
              color: Colors.blue,
            ),
            _buildStatisticCard(
              title: 'Chưa thực hiện',
              count: statistics.notStarted,
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            _buildStatisticCard(
              title: 'Đang thực hiện',
              count: statistics.inProgress,
              icon: Icons.autorenew,
              color: Colors.blue,
            ),
            _buildStatisticCard(
              title: 'Đã hoàn thành',
              count: statistics.completed,
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  // E2: Thong ke cong viec duoc giao va phu trach
  Widget _buildAssignmentStatistics() {
    return FutureBuilder<AssignmentStatistics>(
      future: _assignmentStatisticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return _buildError(
            message:
            'Không thể tải thống kê công việc được giao.\n${snapshot.error}',
            onRetry: _reloadStatistics,
          );
        }

        final statistics = snapshot.data;

        if (statistics == null) {
          return const Text(
            'Không có dữ liệu thống kê phân công.',
          );
        }

        return Column(
          children: [
            _buildStatisticCard(
              title: 'Công việc được giao cho tôi',
              count: statistics.assigned,
              icon: Icons.assignment_ind_outlined,
              color: Colors.deepPurple,
            ),
            _buildStatisticCard(
              title: 'Công việc tôi phụ trách chính',
              count: statistics.responsible,
              icon: Icons.person_pin_circle_outlined,
              color: Colors.teal,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _reloadStatistics,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tổng quan công việc',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatusStatistics(),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Thống kê công việc được giao và phụ trách',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildAssignmentStatistics(),

            const SizedBox(height: 24),

            // E3: Dieu huong den man hinh cong viec sap den han va qua han
            ElevatedButton.icon(
              onPressed: _openDeadlineScreen,
              icon: const Icon(Icons.event_note),
              label: const Text(
                'Công việc sắp đến hạn và quá hạn',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 16),

            const Center(
              child: Text(
                'Kéo xuống để cập nhật thống kê.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
