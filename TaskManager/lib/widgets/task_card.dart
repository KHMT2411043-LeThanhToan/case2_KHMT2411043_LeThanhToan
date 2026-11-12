
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/constants.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (task.status) {
      case TaskStatus.notStarted:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.notStarted:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusLabel() {
    return TaskStatus.labels[task.status] ?? 'Chưa thực hiện';
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getPriorityLabel() {
    return TaskPriority.labels[task.priority] ?? 'Trung bình';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final priorityColor = _getPriorityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          _getStatusIcon(),
          color: statusColor,
          size: 30,
        ),
        title: Text(
          task.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              task.description.isEmpty
                  ? 'Không có mô tả'
                  : task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag,
                  size: 16,
                  color: priorityColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ưu tiên: ${_getPriorityLabel()}',
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          _getStatusLabel(),
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
