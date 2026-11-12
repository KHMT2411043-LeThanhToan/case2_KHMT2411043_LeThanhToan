import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final Task task;

  const AssignTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();

  final TextEditingController _searchController =
  TextEditingController();

  Timer? _debounce;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];

  String? _primaryAssigneeId;

  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    for (final user in widget.task.assignees) {
      _selectedUsers.add({
        '_id': user.id,
        'fullName': user.fullName,
        'email': user.email,
      });
    }

    _primaryAssigneeId = widget.task.primaryAssignee?.id;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String keyword) {
    _debounce?.cancel();

    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () async {
        setState(() {
          _isSearching = true;
        });

        try {
          final users = await _userService.searchUsers(keyword);

          if (!mounted) return;

          setState(() {
            _searchResults = users.where((user) {
              final id = user['_id']?.toString() ?? '';

              return !_selectedUsers.any(
                    (selected) => selected['_id']?.toString() == id,
              );
            }).toList();

            _isSearching = false;
          });
        } catch (error) {
          if (!mounted) return;

          setState(() {
            _isSearching = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.toString().replaceFirst('Exception: ', ''),
              ),
            ),
          );
        }
      },
    );
  }

  void _addUser(Map<String, dynamic> user) {
    final userId = user['_id']?.toString() ?? '';

    if (userId.isEmpty) return;

    if (_selectedUsers.any(
          (item) => item['_id']?.toString() == userId,
    )) {
      return;
    }

    setState(() {
      _selectedUsers.add(user);
      _searchResults.removeWhere(
            (item) => item['_id']?.toString() == userId,
      );

      _searchController.clear();
      _searchResults = [];

      if (_primaryAssigneeId == null) {
        _primaryAssigneeId = userId;
      }
    });
  }

  void _removeUser(Map<String, dynamic> user) {
    final userId = user['_id']?.toString() ?? '';

    setState(() {
      _selectedUsers.removeWhere(
            (item) => item['_id']?.toString() == userId,
      );

      if (_primaryAssigneeId == userId) {
        _primaryAssigneeId = _selectedUsers.isNotEmpty
            ? _selectedUsers.first['_id']?.toString()
            : null;
      }
    });
  }

  Future<void> _saveAssignments() async {
    if (_isSaving) return;

    final assignedTo = _selectedUsers
        .map((user) => user['_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (assignedTo.isNotEmpty &&
        (_primaryAssigneeId == null ||
            !assignedTo.contains(_primaryAssigneeId))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người phụ trách chính.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedTask = await _taskService.updateTaskAssignments(
        taskId: widget.task.id,
        assignedTo: assignedTo,
        primaryAssigneeId: _primaryAssigneeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật người được giao thành công.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, updatedTask);
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao công việc'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.task.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Tìm người dùng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Nhập tên hoặc email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _searchUsers,
          ),

          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _searchResults.map((user) {
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      user['fullName']?.toString() ?? 'Không có tên',
                    ),
                    subtitle: Text(
                      user['email']?.toString() ?? '',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue,
                      ),
                      onPressed: () => _addUser(user),
                    ),
                    onTap: () => _addUser(user),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sách người được giao',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('${_selectedUsers.length} người'),
            ],
          ),
          const SizedBox(height: 8),

          if (_selectedUsers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có người được giao công việc.'),
              ),
            )
          else
            ..._selectedUsers.map((user) {
              final userId = user['_id']?.toString() ?? '';
              final isPrimary = userId == _primaryAssigneeId;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      isPrimary ? Icons.star : Icons.person,
                    ),
                  ),
                  title: Text(
                    user['fullName']?.toString() ?? 'Không có tên',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email']?.toString() ?? ''),
                      if (isPrimary)
                        const Text(
                          'Người phụ trách chính',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'primary') {
                        setState(() {
                          _primaryAssigneeId = userId;
                        });
                      } else if (value == 'remove') {
                        _removeUser(user);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'primary',
                        child: Text('Đặt làm phụ trách chính'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Xóa khỏi danh sách giao việc',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAssignments,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
              ),
            ),
          ),
        ],
      ),
    );
  }
}