
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;

  final TaskService _taskService = TaskService();

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'not_started':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return 'Chưa thực hiện';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'not_started':
        return Icons.radio_button_unchecked;
      case 'in_progress':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_started':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _buildInfo(
      String label,
      String value,
      IconData icon,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.blueGrey,
        ),
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

  // Mở màn hình chỉnh sửa công việc
  Future<void> _openEditScreen() async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: _task),
      ),
    );

    if (!mounted) return;

    if (updatedTask != null) {
      setState(() {
        _task = updatedTask;
      });
    }
  }

  // Xác nhận và xóa công việc
  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text(
          'Bạn có chắc chắn muốn xóa công việc "${_task.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _taskService.deleteTask(
        taskId: _task.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa công việc thành công'),
          backgroundColor: Colors.green,
        ),
      );

      // Quay về danh sách công việc
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          // Nút chỉnh sửa công việc
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa công việc',
            onPressed: _isDeleting ? null : _openEditScreen,
          ),

          // Nút xóa công việc
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Xóa công việc',
            onPressed: _isDeleting ? null : _deleteTask,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _task.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(_task.status),
                            color: _getStatusColor(_task.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusLabel(_task.status),
                            style: TextStyle(
                              color: _getStatusColor(_task.status),
                              fontWeight: FontWeight.bold,
                            ),
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
                _task.description,
                Icons.description_outlined,
              ),

              _buildInfo(
                'Người tạo (ID)',
                _task.createdBy,
                Icons.person_outline,
              ),

              _buildInfo(
                'Người được giao',
                _task.assignedTo.isEmpty
                    ? 'Chưa giao cho ai'
                    : _task.assignedTo.join('\n'),
                Icons.assignment_ind_outlined,
              ),

              _buildInfo(
                'Người đã nhận',
                _task.acceptedBy.isEmpty
                    ? 'Chưa có ai nhận'
                    : _task.acceptedBy.join('\n'),
                Icons.how_to_reg_outlined,
              ),

              _buildInfo(
                'Người được chia sẻ',
                _task.sharedWith.isEmpty
                    ? 'Chưa chia sẻ với ai'
                    : _task.sharedWith.join('\n'),
                Icons.share_outlined,
              ),
            ],
          ),

          if (_isDeleting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
