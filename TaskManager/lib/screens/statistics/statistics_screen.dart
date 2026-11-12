
import 'package:flutter/material.dart';

import '../../models/statistics.dart';
import '../../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() =>
      _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService =
      StatisticsService();

  late Future<Statistics> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    _statisticsFuture =
        _statisticsService.fetchTaskStatisticsByStatus();
  }

  Future<void> _reloadStatistics() async {
    setState(() {
      _loadStatistics();
    });

    await _statisticsFuture;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê công việc'),
        centerTitle: true,
      ),
      body: FutureBuilder<Statistics>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Không thể tải thống kê công việc.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reloadStatistics,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final statistics = snapshot.data;

          if (statistics == null) {
            return const Center(
              child: Text('Không có dữ liệu thống kê.'),
            );
          }

          return RefreshIndicator(
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

                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Kéo xuống để cập nhật thống kê.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
