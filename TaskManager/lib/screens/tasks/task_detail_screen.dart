
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../assignment/assign_task_screen.dart';
import '../sharing/task_sharing_screen.dart';
import 'task_edit_screen.dart';
import 'task_email_history_screen.dart';
import 'task_activity_screen.dart';

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

  void _openEmailHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEmailHistoryScreen(task: _task),
      ),
    );
  }

  void _openActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskActivityScreen(
          taskId: _task.id,
          taskTitle: _task.title,
        ),
      ),
    );
  }

  Future<void> _openSharingScreen() async {
    if (_currentUserId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskSharingScreen(
          task: _task,
          currentUserId: _currentUserId!,
        ),
      ),
    );

    if (!mounted) return;

    await _refreshTask();
  }

  Future<void> _openAssignmentScreen() async {
    final updatedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => AssignTaskScreen(task: _task),
      ),
    );

    if (!mounted) return;

    if (updatedTask != null) {
      setState(() {
        _task = updatedTask;
      });
    } else {
      await _refreshTask();
    }
  }

  bool get _isCreator =>
      _currentUserId != null && _task.createdBy == _currentUserId;

  bool get _isEditor {
    if (_currentUserId == null) return false;

    return _task.sharedPermissions.any(
          (share) =>
      share.userId == _currentUserId &&
          share.permission == 'editor',
    );
  }

  bool get _canEdit => _isCreator || _isEditor;
  bool get _canDelete => _isCreator;

  bool get _isAssignee =>
      _currentUserId != null &&
          _task.assignedTo.contains(_currentUserId);

  bool get _isSharedUser =>
      _currentUserId != null &&
          _task.sharedWith.contains(_currentUserId);

  List<String> get _currentUserRoles {
    final roles = <String>[];

    if (_isCreator) roles.add('Creator');
    if (_isAssignee) roles.add('Assignee');
    if (_isSharedUser) roles.add('Shared User');

    return roles;
  }

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await _authService.getCurrentUserId();

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _isLoadingUser = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể tải thông tin người dùng: '
                '${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    if (date == null) return 'Chưa thiết lập';

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

  Widget _buildPersonTile({
    required String name,
    required String email,
    String? role,
    IconData icon = Icons.person_outline,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          name.isEmpty ? 'Chưa có tên' : name,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.only(top: 8, bottom: 10),
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

  Widget _buildCurrentUserRoles() {
    if (_currentUserRoles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Vai trò của bạn', Icons.badge_outlined),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentUserRoles.map((role) {
            return Chip(
              avatar: Icon(
                role == 'Creator'
                    ? Icons.create
                    : role == 'Assignee'
                    ? Icons.assignment_ind
                    : Icons.visibility,
                size: 18,
              ),
              label: Text(
                role == 'Creator'
                    ? 'Người tạo'
                    : role == 'Assignee'
                    ? 'Người được giao'
                    : 'Người được chia sẻ',
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<bool> _refreshTask() async {
    try {
      final tasks = await _taskService.fetchTasks();

      final updatedTasks = tasks.where(
            (task) => task.id == _task.id,
      );

      if (updatedTasks.isNotEmpty && mounted) {
        setState(() {
          _task = updatedTasks.first;
        });
      }

      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể tải lại công việc: '
                  '${error.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      return false;
    }
  }

  Future<void> _updateMyProgress(String status) async {
    if (!_isAssignee) return;

    try {
      await _taskService.updateMyProgress(
        taskId: _task.id,
        status: status,
      );

      if (!mounted) return;

      final refreshed = await _refreshTask();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshed
                ? 'Cập nhật tiến độ thành công'
                : 'Đã cập nhật tiến độ, nhưng chưa tải lại được dữ liệu.',
          ),
          backgroundColor: refreshed ? Colors.green : Colors.orange,
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

  Widget _buildProgressSection() {
    if (_task.assignees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Tiến độ từng người',
          Icons.trending_up,
        ),
        ..._task.assignees.map((person) {
          final progress = _task.assigneeProgress
              .where((item) => item.userId == person.id)
              .toList();

          final status = progress.isNotEmpty
              ? progress.first.status
              : 'not_started';

          final isMyProgress =
              _currentUserId != null &&
                  person.id == _currentUserId;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName.isEmpty
                        ? person.email
                        : person.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isMyProgress) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Cập nhật tiến độ của bạn',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'not_started',
                          child: Text('Chưa thực hiện'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('Đang thực hiện'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Đã hoàn thành'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null && value != status) {
                          _updateMyProgress(value);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text(
          'Bạn có chắc chắn muốn xóa công việc "${_task.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
      await _taskService.deleteTask(taskId: _task.id);

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
          if (!_isLoadingUser)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Lịch sử gửi email',
              onPressed: _isDeleting ? null : _openEmailHistory,
            ),
          if (!_isLoadingUser)
            IconButton(
              icon: const Icon(Icons.timeline),
              tooltip: 'Lịch sử hoạt động',
              onPressed: _isDeleting ? null : _openActivityHistory,
            ),
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
                            style: TextStyle(fontWeight: FontWeight.w500),
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
              _buildCurrentUserRoles(),
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
              if (!_isLoadingUser && _isCreator) ...[
                _buildSectionTitle(
                  'Quản lý giao việc',
                  Icons.assignment_ind,
                ),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.assignment_ind),
                    ),
                    title: const Text(
                      'Quản lý người được giao',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Thêm, xóa hoặc thay đổi người phụ trách',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),
                    onTap: _isDeleting ? null : _openAssignmentScreen,
                  ),
                ),
              ],
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
              _buildProgressSection(),
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
              _buildSectionTitle(
                'Người được chia sẻ',
                Icons.share_outlined,
              ),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.share_outlined),
                  ),
                  title: const Text(
                    'Quản lý chia sẻ công việc',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${_task.sharedUsers.length} người được chia sẻ',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: _isLoadingUser || _isDeleting
                      ? null
                      : _openSharingScreen,
                ),
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
