
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;

  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  String? _currentUserId;
  bool _isLoadingUser = true;
  bool _isDeleting = false;

  bool get _isCreator {
    return _currentUserId != null &&
        _task.createdBy == _currentUserId;
  }

  bool get _isEditor {
    if (_currentUserId == null) return false;

    return _task.sharedPermissions.any((share) {
      return share.userId == _currentUserId &&
          share.permission == 'editor';
    });
  }

  bool get _canEdit {
    return _isCreator || _isEditor;
  }

  bool get _canDelete {
    return _isCreator;
  }

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authService.getCurrentUserId();

    if (!mounted) return;

    setState(() {
      _currentUserId = userId;
      _isLoadingUser = false;
    });
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

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return 'Trung bình';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa thiết lập';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'low':
        return Icons.arrow_downward;
      case 'medium':
        return Icons.remove;
      case 'high':
        return Icons.arrow_upward;
      default:
        return Icons.remove;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
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

  Widget _buildPersonTile({
    required String name,
    required String email,
    String? role,
    IconData icon = Icons.person_outline,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          name.isEmpty ? 'Chưa có tên' : name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email),
            ],
            if (role != null) ...[
              const SizedBox(height: 4),
              Text(
                role,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: email.isNotEmpty && role != null,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 10,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Lay quyen chia se cua mot nguoi dung
  String _getSharePermission(String userId) {
    for (final share in _task.sharedPermissions) {
      if (share.userId == userId) {
        return share.permission;
      }
    }

    return 'viewer';
  }

  // Tai lai thong tin cong viec sau khi thay doi quyen
  Future<void> _refreshTask() async {
    final tasks = await _taskService.fetchTasks();

    final updatedTasks = tasks.where(
          (task) => task.id == _task.id,
    );

    if (updatedTasks.isNotEmpty && mounted) {
      setState(() {
        _task = updatedTasks.first;
      });
    }
  }

  // Hien thi hop thoai thay doi quyen chia se
  Future<void> _manageSharePermission(
      String userId,
      String userName,
      ) async {
    String selectedPermission = _getSharePermission(userId);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Quản lý quyền của $userName'),
              content: RadioGroup<String>(
                groupValue: selectedPermission,
                onChanged: (value) {
                  setDialogState(() {
                    selectedPermission = value!;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: const Text('Viewer'),
                      subtitle: const Text('Chỉ được xem công việc'),
                      value: 'viewer',
                    ),
                    RadioListTile<String>(
                      title: const Text('Editor'),
                      subtitle: const Text('Được xem và chỉnh sửa'),
                      value: 'editor',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      selectedPermission,
                    );
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    try {
      await _taskService.updateSharePermission(
        taskId: _task.id,
        userId: userId,
        permission: result,
      );

      await _refreshTask();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thay đổi quyền thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

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

  // Thu hoi quyen chia se
  Future<void> _revokeSharePermission(
      String userId,
      String userName,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thu hồi quyền chia sẻ'),
        content: Text(
          'Bạn có chắc muốn thu hồi quyền chia sẻ của $userName không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Thu hồi',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _taskService.revokeSharePermission(
        taskId: _task.id,
        userId: userId,
      );

      await _refreshTask();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thu hồi quyền chia sẻ thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

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
          if (!_isLoadingUser && _canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa công việc',
              onPressed: _isDeleting ? null : _openEditScreen,
            ),
          if (!_isLoadingUser && _canDelete)
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _getPriorityIcon(_task.priority),
                            color: _getPriorityColor(_task.priority),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mức độ ưu tiên: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getPriorityLabel(_task.priority),
                            style: TextStyle(
                              color: _getPriorityColor(_task.priority),
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
                'Ngày bắt đầu',
                _formatDate(_task.startDate),
                Icons.calendar_today,
              ),

              _buildInfo(
                'Hạn hoàn thành',
                _formatDate(_task.dueDate),
                Icons.event,
              ),

              _buildInfo(
                'Người tạo (ID)',
                _task.createdBy,
                Icons.person_outline,
              ),

              // Nguoi phu trach chinh
              _buildSectionTitle(
                'Người phụ trách chính',
                Icons.star_outline,
              ),

              if (_task.primaryAssignee != null)
                _buildPersonTile(
                  name: _task.primaryAssignee!.fullName,
                  email: _task.primaryAssignee!.email,
                  role: 'Người phụ trách chính',
                  icon: Icons.star,
                )
              else
                _buildInfo(
                  'Người phụ trách chính',
                  'Chưa chọn người phụ trách chính',
                  Icons.star_outline,
                ),

              // Danh sach nguoi duoc giao
              _buildSectionTitle(
                'Người được giao',
                Icons.assignment_ind_outlined,
              ),

              if (_task.assignees.isEmpty)
                _buildInfo(
                  'Người được giao',
                  'Chưa giao cho ai',
                  Icons.assignment_ind_outlined,
                )
              else
                ..._task.assignees.map((person) {
                  final isPrimary =
                      _task.primaryAssignee?.id == person.id;

                  return _buildPersonTile(
                    name: person.fullName,
                    email: person.email,
                    role: isPrimary
                        ? 'Người phụ trách chính'
                        : 'Người được giao',
                    icon: isPrimary
                        ? Icons.star
                        : Icons.assignment_ind_outlined,
                  );
                }),

              _buildInfo(
                'Người đã nhận (ID)',
                _task.acceptedBy.isEmpty
                    ? 'Chưa có ai nhận'
                    : _task.acceptedBy.join('\n'),
                Icons.how_to_reg_outlined,
              ),

              // Danh sach nguoi duoc chia se
              _buildSectionTitle(
                'Người được chia sẻ',
                Icons.share_outlined,
              ),

              if (_task.sharedUsers.isEmpty)
                _buildInfo(
                  'Người được chia sẻ',
                  'Chưa chia sẻ với ai',
                  Icons.share_outlined,
                )
              else
                ..._task.sharedUsers.map((person) {
                  final permission =
                  _getSharePermission(person.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.share),
                      ),
                      title: Text(
                        person.fullName.isEmpty
                            ? 'Chưa có tên'
                            : person.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (person.email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(person.email),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            permission == 'editor'
                                ? 'Quyền: Editor - Được phép chỉnh sửa'
                                : 'Quyền: Viewer - Chỉ được xem',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: person.email.isNotEmpty,
                      trailing: _isCreator
                          ? PopupMenuButton<String>(
                        tooltip: 'Quản lý quyền chia sẻ',
                        onSelected: (value) {
                          if (value == 'edit') {
                            _manageSharePermission(
                              person.id,
                              person.fullName,
                            );
                          } else if (value == 'revoke') {
                            _revokeSharePermission(
                              person.id,
                              person.fullName,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Text('Thay đổi quyền'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'revoke',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_remove_outlined,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Thu hồi quyền',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                          : null,
                    ),
                  );
                }),
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
