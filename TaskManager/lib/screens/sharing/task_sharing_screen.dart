
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';

class TaskSharingScreen extends StatefulWidget {
  final Task task;
  final String currentUserId;

  const TaskSharingScreen({
    super.key,
    required this.task,
    required this.currentUserId,
  });

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  late Task _task;

  final TaskService _taskService = TaskService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  bool get _isCreator =>
      widget.currentUserId.isNotEmpty &&
          _task.createdBy == widget.currentUserId;

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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _getErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _addSharedUser() async {
    if (!_isCreator || _isLoading) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddSharedUserDialog(
        task: _task,
        currentUserId: widget.currentUserId,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.addSharedUser(
        taskId: _task.id,
        userId: result['userId'] as String,
        permission: result['permission'] as String,
      );

      await _refreshTask();

      _showMessage(
        'Mời người chia sẻ thành công. Email đã được xử lý bởi hệ thống.',
      );
    } catch (error) {
      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _manageSharePermission(
      String userId,
      String userName,
      ) async {
    if (!_isCreator || _isLoading) return;

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
                  children: const [
                    RadioListTile<String>(
                      title: Text('Viewer'),
                      subtitle: Text('Chỉ được xem công việc'),
                      value: 'viewer',
                    ),
                    RadioListTile<String>(
                      title: Text('Editor'),
                      subtitle: Text('Được xem và chỉnh sửa'),
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

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.updateSharePermission(
        taskId: _task.id,
        userId: userId,
        permission: result,
      );

      await _refreshTask();

      _showMessage('Thay đổi quyền thành công');
    } catch (error) {
      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _revokeSharePermission(
      String userId,
      String userName,
      ) async {
    if (!_isCreator || _isLoading) return;

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

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.revokeSharePermission(
        taskId: _task.id,
        userId: userId,
      );

      await _refreshTask();

      _showMessage('Thu hồi quyền chia sẻ thành công');
    } catch (error) {
      _showMessage(_getErrorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSharedUserCard(TaskAssignee person) {
    final permission = _getSharePermission(person.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.share),
        ),
        title: Text(
          person.fullName.isEmpty ? 'Chưa có tên' : person.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chia sẻ'),
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
                      const Text(
                        'Công việc',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Người được chia sẻ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('${_task.sharedUsers.length} người'),
                ],
              ),
              const SizedBox(height: 12),
              if (_isCreator) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _addSharedUser,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Thêm người chia sẻ'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_task.sharedUsers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('Chưa chia sẻ công việc với ai'),
                    ),
                  ),
                )
              else
                ..._task.sharedUsers.map(_buildSharedUserCard),
            ],
          ),
          if (_isLoading)
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

// Hộp thoại tìm kiếm và mời người chia sẻ.
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
                const Center(
                  child: CircularProgressIndicator(),
                ),
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
