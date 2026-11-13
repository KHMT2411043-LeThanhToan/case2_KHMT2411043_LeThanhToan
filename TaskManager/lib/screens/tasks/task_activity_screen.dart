
import 'package:flutter/material.dart';

import '../../models/task_activity.dart';
import '../../services/activity_service.dart';

class TaskActivityScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskActivityScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskActivityScreen> createState() =>
      _TaskActivityScreenState();
}

class _TaskActivityScreenState
    extends State<TaskActivityScreen> {
  final ActivityService _activityService = ActivityService();

  late Future<List<TaskActivity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    _activitiesFuture =
        _activityService.fetchTaskActivities(widget.taskId);
  }

  Future<void> _refreshActivities() async {
    setState(() {
      _loadActivities();
    });

    try {
      await _activitiesFuture;
    } catch (_) {
      // FutureBuilder se hien thi thong bao loi.
    }
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year lúc $hour:$minute';
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_task;
      case 'updated':
        return Icons.edit;
      case 'status_changed':
        return Icons.sync;
      case 'assigned':
        return Icons.person_add;
      case 'assignment_removed':
        return Icons.person_remove;
      case 'accepted':
        return Icons.how_to_reg;
      case 'progress_updated':
        return Icons.trending_up;
      case 'shared':
        return Icons.share;
      case 'permission_changed':
        return Icons.admin_panel_settings;
      case 'share_revoked':
        return Icons.link_off;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'updated':
      case 'permission_changed':
        return Colors.blue;
      case 'status_changed':
      case 'progress_updated':
        return Colors.orange;
      case 'assignment_removed':
      case 'share_revoked':
        return Colors.red;
      case 'assigned':
      case 'accepted':
      case 'shared':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildActivityItem(
    TaskActivity activity,
    bool isLast,
  ) {
    final color = _getActionColor(activity.action);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    _getActionIcon(activity.action),
                    color: color,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            activity.userName,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(activity.createdAt),
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có lịch sử hoạt động',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Các hoạt động của công việc sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
        title: const Text('Lịch sử hoạt động'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.taskTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<TaskActivity>>(
              future: _activitiesFuture,
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
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _refreshActivities,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshActivities,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.55,
                          child: _buildEmptyState(),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshActivities,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      return _buildActivityItem(
                        activities[index],
                        index == activities.length - 1,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
