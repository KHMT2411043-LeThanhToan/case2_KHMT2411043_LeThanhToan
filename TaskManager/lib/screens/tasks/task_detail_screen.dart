
import 'package:flutter/material.dart';
import '../../models/task.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  Widget _buildInfo(
      String label,
      String value,
      IconData icon,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? 'Chưa có thông tin' : value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        task.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task.completed
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.completed
                            ? 'Hoàn thành'
                            : 'Chưa xong',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfo(
            'Mô tả',
            task.description,
            Icons.description_outlined,
          ),
          _buildInfo(
            'Người tạo (ID)',
            task.createdBy,
            Icons.person_outline,
          ),
          _buildInfo(
            'Người được giao',
            task.assignedTo.isEmpty
                ? 'Chưa giao cho ai'
                : task.assignedTo.join('\n'),
            Icons.assignment_ind_outlined,
          ),
          _buildInfo(
            'Người đã nhận',
            task.acceptedBy.isEmpty
                ? 'Chưa có ai nhận'
                : task.acceptedBy.join('\n'),
            Icons.how_to_reg_outlined,
          ),
          _buildInfo(
            'Người được chia sẻ',
            task.sharedWith.isEmpty
                ? 'Chưa chia sẻ với ai'
                : task.sharedWith.join('\n'),
            Icons.share_outlined,
          ),
        ],
      ),
    );
  }
}
