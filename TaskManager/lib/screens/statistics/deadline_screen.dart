
import 'package:flutter/material.dart';

import '../../models/deadline_statistics.dart';
import '../../services/deadline_service.dart';

class DeadlineScreen extends StatefulWidget {
  const DeadlineScreen({super.key});

  @override
  State<DeadlineScreen> createState() => _DeadlineScreenState();
}

class _DeadlineScreenState extends State<DeadlineScreen> {
  final DeadlineService _deadlineService = DeadlineService();

  late Future<DeadlineStatistics> _deadlineFuture;

  @override
  void initState() {
    super.initState();
    _loadDeadlines();
  }

  void _loadDeadlines() {
    _deadlineFuture = _deadlineService.fetchDeadlineTasks();
  }

  Future<void> _reloadDeadlines() async {
    setState(() {
      _loadDeadlines();
    });

    try {
      await _deadlineFuture;
    } catch (_) {
      // Loi duoc hien thi trong FutureBuilder.
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa xác định';
    }

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day/$month/$year';
  }

  String _statusText(String status) {
    switch (status) {
      case 'not_started':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return status;
    }
  }

  String _priorityText(String priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return priority;
    }
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _reloadDeadlines,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(
      DeadlineTask task, {
        required bool isOverdue,
      }) {
    final color = isOverdue ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.event_available,
                  color: color,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.description,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hạn: ${_formatDate(task.dueDate)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(_statusText(task.status)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    'Ưu tiên: ${_priorityText(task.priority)}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(
                    isOverdue ? 'Quá hạn' : 'Sắp đến hạn',
                  ),
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<DeadlineTask> tasks,
    required bool isOverdue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CircleAvatar(
              radius: 15,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                tasks.length.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: Text(
                  isOverdue
                      ? 'Không có công việc quá hạn.'
                      : 'Không có công việc sắp đến hạn.',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          )
        else
          ...tasks.map(
                (task) => _buildDeadlineCard(
              task,
              isOverdue: isOverdue,
            ),
          ),
      ],
    );
  }

  Widget _buildDeadlineContent(DeadlineStatistics statistics) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Sắp đến hạn',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statistics.upcomingCount.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 55,
                  child: VerticalDivider(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Quá hạn',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statistics.overdueCount.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildDeadlineSection(
          title: 'Công việc sắp đến hạn',
          icon: Icons.event_available,
          color: Colors.orange,
          tasks: statistics.upcomingTasks,
          isOverdue: false,
        ),
        const SizedBox(height: 24),
        _buildDeadlineSection(
          title: 'Công việc quá hạn',
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          tasks: statistics.overdueTasks,
          isOverdue: true,
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Kéo xuống để cập nhật danh sách.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc theo thời hạn'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _reloadDeadlines,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadDeadlines,
        child: FutureBuilder<DeadlineStatistics>(
          future: _deadlineFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildLoading(),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildError(
                    'Không thể tải danh sách công việc.\n${snapshot.error}',
                  ),
                ],
              );
            }

            final statistics = snapshot.data;

            if (statistics == null) {
              return const Center(
                child: Text('Không có dữ liệu công việc.'),
              );
            }

            return _buildDeadlineContent(statistics);
          },
        ),
      ),
    );
  }
}
