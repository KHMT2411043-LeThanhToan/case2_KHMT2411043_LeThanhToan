
import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../services/task_service.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService =
      NotificationService();

  final TaskService _taskService = TaskService();

  late Future<List<AppNotification>> _notificationsFuture;

  bool _isMarkingAllRead = false;
  String? _openingNotificationId;

  @override
  void initState() {
    super.initState();
    _notificationsFuture =
        _notificationService.fetchNotifications();
  }

  void _reloadNotifications() {
    setState(() {
      _notificationsFuture =
          _notificationService.fetchNotifications();
    });
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) return;

      _reloadNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  Future<void> _openNotification(
    AppNotification notification,
  ) async {
    if (_openingNotificationId != null) return;

    setState(() {
      _openingNotificationId = notification.id;
    });

    try {
      // Đánh dấu đã đọc trước khi mở công việc.
      if (!notification.isRead) {
        await _notificationService.markAsRead(
          notification.id,
        );

        if (!mounted) return;

        _reloadNotifications();
      }

      // Kiểm tra thông báo có liên kết với công việc không.
      final taskId = notification.taskId;

      if (taskId == null || taskId.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thông báo này không liên kết với công việc.',
            ),
          ),
        );

        return;
      }

      // Lấy danh sách công việc người dùng có quyền truy cập.
      final tasks = await _taskService.fetchTasks();

      if (!mounted) return;

      // Tìm công việc tương ứng với thông báo.
      final matchingTasks = tasks.where(
        (task) => task.id == taskId,
      );

      if (matchingTasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Công việc không còn khả dụng hoặc bạn không có quyền truy cập.',
            ),
          ),
        );

        return;
      }

      final task = matchingTasks.first;

      // Mở màn hình chi tiết công việc.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailScreen(
            task: task,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể mở thông báo: ${e.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingNotificationId = null;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind_outlined;

      case 'task_shared':
        return Icons.share_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  Widget _buildNotificationItem(
    AppNotification notification,
  ) {
    final isOpening =
        _openingNotificationId == notification.id;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      color: notification.isRead
          ? null
          : Theme.of(context)
              .colorScheme
              .primaryContainer
          .withValues(alpha: 0.35),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.grey.shade200
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _getNotificationIcon(notification.type),
            color: notification.isRead
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.senderName.isNotEmpty)
                Text(
                  'Người gửi: ${notification.senderName}',
                ),
              if (notification.taskTitle.isNotEmpty)
                Text(
                  'Công việc: ${notification.taskTitle}',
                ),
              const SizedBox(height: 4),
              Text(
                _formatDate(notification.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    'Chưa đọc',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: isOpening
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: isOpening
            ? null
            : () => _openNotification(notification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _isMarkingAllRead
                ? null
                : _markAllAsRead,
            icon: _isMarkingAllRead
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.done_all),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
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
                    Text(
                      'Không thể tải thông báo.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _reloadNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Bạn chưa có thông báo nào.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reloadNotifications();
              await _notificationsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(
                  notifications[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
