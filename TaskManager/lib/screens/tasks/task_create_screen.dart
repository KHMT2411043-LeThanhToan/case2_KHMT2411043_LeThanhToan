
import 'package:flutter/material.dart';

import '../../services/task_service.dart';
import '../../services/user_service.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _shareSearchController = TextEditingController();

  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();

  final List<Map<String, dynamic>> _selectedAssignees = [];
  final List<Map<String, dynamic>> _selectedSharedUsers = [];

  final Map<String, String> _sharedUserPermissions = {};

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _shareSearchResults = [];

  String _priority = 'medium';
  String? _primaryAssigneeId;

  DateTime? _startDate;
  DateTime? _dueDate;

  bool _isSearching = false;
  bool _isSearchingSharedUsers = false;
  bool _isCreating = false;

  // Tim kiem nguoi duoc giao
  Future<void> _searchUsers(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await _userService.searchUsers(keyword);

      if (!mounted) return;

      setState(() {
        _searchResults = users.where((user) {
          final id = user['_id']?.toString();

          return !_selectedAssignees.any(
                (selected) => selected['_id']?.toString() == id,
          ) &&
              !_selectedSharedUsers.any(
                    (selected) => selected['_id']?.toString() == id,
              );
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Them nguoi duoc giao
  void _addAssignee(Map<String, dynamic> user) {
    final userId = user['_id']?.toString();

    if (userId == null || userId.isEmpty) return;

    if (_selectedAssignees.any(
          (item) => item['_id']?.toString() == userId,
    )) {
      return;
    }

    setState(() {
      _selectedAssignees.add(user);

      _searchResults.removeWhere(
            (item) => item['_id']?.toString() == userId,
      );

      _searchController.clear();
      _searchResults = [];

      // Neu chua co nguoi phu trach chinh thi chon nguoi dau tien
      _primaryAssigneeId ??= userId;
    });
  }

  // Xoa nguoi duoc giao
  void _removeAssignee(String userId) {
    setState(() {
      _selectedAssignees.removeWhere(
            (user) => user['_id']?.toString() == userId,
      );

      if (_primaryAssigneeId == userId) {
        _primaryAssigneeId = _selectedAssignees.isNotEmpty
            ? _selectedAssignees.first['_id']?.toString()
            : null;
      }
    });
  }

  // Tim kiem nguoi duoc chia se
  Future<void> _searchSharedUsers(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _shareSearchResults = [];
        _isSearchingSharedUsers = false;
      });
      return;
    }

    setState(() {
      _isSearchingSharedUsers = true;
    });

    try {
      final users = await _userService.searchUsers(keyword);

      if (!mounted) return;

      setState(() {
        _shareSearchResults = users.where((user) {
          final id = user['_id']?.toString();

          final isAssignee = _selectedAssignees.any(
                (item) => item['_id']?.toString() == id,
          );

          final isAlreadyShared = _selectedSharedUsers.any(
                (item) => item['_id']?.toString() == id,
          );

          return !isAssignee && !isAlreadyShared;
        }).toList();

        _isSearchingSharedUsers = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSearchingSharedUsers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  // Them nguoi duoc chia se
  void _addSharedUser(Map<String, dynamic> user) {
    final userId = user['_id']?.toString();

    if (userId == null || userId.isEmpty) return;

    if (_selectedSharedUsers.any(
          (item) => item['_id']?.toString() == userId,
    )) {
      return;
    }

    if (_selectedAssignees.any(
          (item) => item['_id']?.toString() == userId,
    )) {
      return;
    }

    setState(() {
      _selectedSharedUsers.add(user);

      // Mac dinh quyen xem
      _sharedUserPermissions[userId] = 'viewer';

      _shareSearchResults.removeWhere(
            (item) => item['_id']?.toString() == userId,
      );

      _shareSearchController.clear();
      _shareSearchResults = [];
    });
  }

  // Xoa nguoi duoc chia se
  void _removeSharedUser(String userId) {
    setState(() {
      _selectedSharedUsers.removeWhere(
            (user) => user['_id']?.toString() == userId,
      );

      _sharedUserPermissions.remove(userId);
    });
  }

  // Chon ngay
  Future<void> _selectDate(bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_dueDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = selectedDate;
      } else {
        _dueDate = selectedDate;
      }
    });
  }

  // Tao cong viec
  Future<void> _createTask() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên công việc'),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _taskService.createTask(
        title: title,
        description: _descriptionController.text.trim(),
        priority: _priority,
        startDate: _startDate,
        dueDate: _dueDate,
        assignedTo: _selectedAssignees
            .map((user) => user['_id'].toString())
            .toList(),
        primaryAssigneeId: _primaryAssigneeId,
        sharedWith: _selectedSharedUsers
            .map((user) => user['_id'].toString())
            .toList(),
        sharedPermissions: _selectedSharedUsers.map((user) {
          final userId = user['_id'].toString();

          return {
            'user': userId,
            'permission': _sharedUserPermissions[userId] ?? 'viewer',
          };
        }).toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo công việc thành công'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo công việc: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _shareSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo công việc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên công việc *',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Mức độ ưu tiên',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'low',
                  child: Text('Thấp'),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Text('Trung bình'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text('Cao'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _priority = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Ngày bắt đầu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _selectDate(true),
            ),

            const Divider(),

            const Text(
              'Hạn hoàn thành',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_formatDate(_dueDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _selectDate(false),
            ),

            const Divider(height: 32),

            const Text(
              'Giao công việc cho người khác',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm theo tên hoặc email',
                border: const OutlineInputBorder(),
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
              ),
              onChanged: _searchUsers,
            ),

            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _searchResults.map((user) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(user['fullName'] ?? 'Không có tên'),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => _addAssignee(user),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),

            if (_selectedAssignees.isNotEmpty) ...[
              const Text(
                'Danh sách người được giao',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              ..._selectedAssignees.map((user) {
                final userId = user['_id'].toString();

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(user['fullName'] ?? 'Không có tên'),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeAssignee(userId),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              const Text(
                'Người phụ trách chính',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _primaryAssigneeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _selectedAssignees.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['_id'].toString(),
                    child: Text(
                      user['fullName'] ?? 'Không có tên',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _primaryAssigneeId = value;
                  });
                },
              ),
            ],

            const Divider(height: 32),

            const Text(
              'Chia sẻ công việc',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Chọn quyền cho từng người: Viewer hoặc Editor.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _shareSearchController,
              decoration: InputDecoration(
                labelText: 'Tìm người muốn chia sẻ',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.people_outline),
                suffixIcon: _isSearchingSharedUsers
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
              ),
              onChanged: _searchSharedUsers,
            ),

            if (_shareSearchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _shareSearchResults.map((user) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(user['fullName'] ?? 'Không có tên'),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => _addSharedUser(user),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            if (_selectedSharedUsers.isNotEmpty) ...[
              const Text(
                'Danh sách người được chia sẻ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              ..._selectedSharedUsers.map((user) {
                final userId = user['_id'].toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.people_outline),
                          ),
                          title: Text(user['fullName'] ?? 'Không có tên'),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeSharedUser(userId),
                          ),
                        ),

                        DropdownButtonFormField<String>(
                          initialValue:
                          _sharedUserPermissions[userId] ?? 'viewer',
                          decoration: const InputDecoration(
                            labelText: 'Quyền truy cập',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'viewer',
                              child: Text('Viewer - Chỉ xem'),
                            ),
                            DropdownMenuItem(
                              value: 'editor',
                              child: Text('Editor - Được chỉnh sửa'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _sharedUserPermissions[userId] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createTask,
                child: _isCreating
                    ? const CircularProgressIndicator()
                    : const Text('Tạo công việc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
