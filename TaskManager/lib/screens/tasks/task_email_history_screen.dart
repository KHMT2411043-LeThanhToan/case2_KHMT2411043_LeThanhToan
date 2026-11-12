
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';

class TaskEmailHistoryScreen extends StatefulWidget {
  final Task task;

  const TaskEmailHistoryScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskEmailHistoryScreen> createState() =>
      _TaskEmailHistoryScreenState();
}

class _TaskEmailHistoryScreenState
    extends State<TaskEmailHistoryScreen> {
  final TaskService _taskService = TaskService();

  List<Map<String, dynamic>> _emailLogs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmailLogs();
  }

  Future<void> _loadEmailLogs() async {
    try {
      final logs = await _taskService.fetchEmailLogs(
        taskId: widget.task.id,
      );

      if (!mounted) return;

      setState(() {
        _emailLogs = logs;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _eventName(dynamic value) {
    switch (value?.toString()) {
      case 'task_assigned':
        return 'Giao công việc';
      case 'task_shared':
        return 'Chia sẻ công việc';
      case 'task_updated':
        return 'Cập nhật công việc';
      case 'task_completed':
        return 'Hoàn thành công việc';
      case 'task_due_reminder':
        return 'Nhắc hạn công việc';
      default:
        return value?.toString() ?? 'Thông báo';
    }
  }

  Color _statusColor(dynamic value) {
    switch (value?.toString()) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusName(dynamic value) {
    switch (value?.toString()) {
      case 'sent':
        return 'Đã gửi';
      case 'failed':
        return 'Gửi thất bại';
      default:
        return 'Đang chờ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử gửi email'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Không thể tải lịch sử gửi email:\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadEmailLogs();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_emailLogs.isEmpty) {
      return const Center(
        child: Text('Chưa có lịch sử gửi email.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmailLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _emailLogs.length,
        itemBuilder: (context, index) {
          final log = _emailLogs[index];
          final status = log['status'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.email_outlined,
                color: _statusColor(status),
                size: 30,
              ),
              title: Text(
                log['recipientEmail']?.toString() ??
                    'Không rõ người nhận',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Loại thông báo: ${_eventName(log['eventType'])}',
                  ),
                  Text(
                    'Tiêu đề: ${log['subject'] ?? 'Không có'}',
                  ),
                  Text(
                    'Thời gian: ${DateFormatter.formatDateTimeValue(
                      log['sentAt'] ?? log['createdAt'],
                    )}',
                  ),
                  Text(
                    'Trạng thái: ${_statusName(status)}',
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (log['errorMessage'] != null &&
                      log['errorMessage'].toString().isNotEmpty)
                    Text(
                      'Lỗi: ${log['errorMessage']}',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
