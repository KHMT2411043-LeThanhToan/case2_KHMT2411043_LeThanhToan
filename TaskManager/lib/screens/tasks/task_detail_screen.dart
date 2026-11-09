
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'task_edit_screen.dart';
import 'task_email_history_screen.dart';

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

  String _getSharePermission(String userId) {
    for (final share in _task.sharedPermissions) {
      if (share.userId == userId) {
        return share.permission;
      }
    }

    return 'viewer';
  }

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

  Future<void> _addSharedUser() async {
    if (!_isCreator) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddSharedUserDialog(
        task: _task,
        currentUserId: _currentUserId ?? '',
      ),
    );

    if (result == null || !mounted) return;

    try {
      await _taskService.addSharedUser(
        taskId: _task.id,
        userId: result['userId'] as String,
        permission: result['permission'] as String,
      );

      await _refreshTask();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mời người chia sẻ thành công. Email đã được xử lý bởi hệ thống.',
          ),
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

  Future<void> _updateMyProgress(String status) async {
    if (!_isAssignee) return;

    try {
      await _taskService.updateMyProgress(
        taskId: _task.id,
        status: status,
      );

      await _refreshTask();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật tiến độ thành công'),
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
                  if (value == null) return;
                  setDialogState(() {
                    selectedPermission = value;
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
                    Navigator.pop(dialogContext, selectedPermission);
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
              if (!_isLoadingUser && _isCreator) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _addSharedUser,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Thêm người chia sẻ'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_task.sharedUsers.isEmpty)
                _buildInfo(
                  'Người được chia sẻ',
                  'Chưa chia sẻ với ai',
                  Icons.share_outlined,
                )
              else
                ..._task.sharedUsers.map((person) {
                  final permission = _getSharePermission(person.id);

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
                                  style: TextStyle(color: Colors.red),
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

// Hộp thoại riêng: controller được quản lý theo vòng đời StatefulWidget.
class AddSharedUserDialog extends StatefulWidget {
  final Task task;
  final String currentUserId;

  const AddSharedUserDialog({
    super.key,
    required this.task,
    required this.currentUserId,
  });

  @override
  State<AddSharedUserDialog> createState() =>
      _AddSharedUserDialogState();
}

class _AddSharedUserDialogState extends State<AddSharedUserDialog> {
  final TextEditingController _searchController =
  TextEditingController();

  final UserService _userService = UserService();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;

  String _selectedPermission = 'viewer';
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty) {
      setState(() {
        _searchError = 'Vui lòng nhập tên hoặc email.';
        _searchResults = [];
        _selectedUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
      _selectedUser = null;
    });

    try {
      final users = await _userService.searchUsers(keyword);

      if (!mounted) return;

      final filteredUsers = users.where((user) {
        final userId =
        (user['_id'] ?? user['id'] ?? '').toString();

        if (userId.isEmpty) return false;
        if (userId == widget.currentUserId) return false;
        if (widget.task.assignedTo.contains(userId)) return false;
        if (widget.task.sharedWith.contains(userId)) return false;

        return true;
      }).toList();

      setState(() {
        _searchResults = filteredUsers;
        _isSearching = false;

        if (filteredUsers.isEmpty) {
          _searchError =
          'Không tìm thấy người dùng phù hợp hoặc người dùng đã tham gia công việc.';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
        _searchError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _submit() {
    if (_selectedUser == null) return;

    final userId =
    (_selectedUser!['_id'] ?? _selectedUser!['id'] ?? '')
        .toString();

    if (userId.isEmpty) return;

    Navigator.of(context).pop({
      'userId': userId,
      'permission': _selectedPermission,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mời người chia sẻ'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Công việc: ${widget.task.title}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Tên hoặc email người dùng',
                  hintText: 'Nhập tên hoặc email',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _isSearching ? null : _searchUsers,
                  ),
                ),
                onSubmitted: (_) => _searchUsers(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchUsers,
                  icon: const Icon(Icons.search),
                  label: const Text('Tìm kiếm'),
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_searchError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _searchError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Kết quả tìm kiếm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._searchResults.map((user) {
                  final userId =
                  (user['_id'] ?? user['id'] ?? '').toString();
                  final fullName =
                  (user['fullName'] ?? '').toString();
                  final email = (user['email'] ?? '').toString();

                  final selectedId = _selectedUser == null
                      ? null
                      : (_selectedUser!['_id'] ??
                      _selectedUser!['id'] ??
                      '')
                      .toString();

                  final isSelected = selectedId == userId;

                  return Card(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.12)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : Icons.person_outline,
                        ),
                      ),
                      title: Text(
                        fullName.isEmpty ? 'Chưa có tên' : fullName,
                      ),
                      subtitle: Text(email),
                      trailing: isSelected
                          ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                        });
                      },
                    ),
                  );
                }),
              ],
              if (_selectedUser != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Người được chọn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  (_selectedUser!['fullName'] ?? '').toString(),
                ),
                Text(
                  (_selectedUser!['email'] ?? '').toString(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPermission,
                  decoration: const InputDecoration(
                    labelText: 'Quyền chia sẻ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Viewer - Chỉ được xem'),
                    ),
                    DropdownMenuItem(
                      value: 'editor',
                      child: Text('Editor - Được chỉnh sửa'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPermission = value;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          onPressed: _selectedUser == null ? null : _submit,
          icon: const Icon(Icons.person_add),
          label: const Text('Gửi lời mời'),
        ),
      ],
    );
  }
}
