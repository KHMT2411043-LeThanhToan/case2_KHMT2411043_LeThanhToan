
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'task_detail_screen.dart';
import 'task_create_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();

  late Future<List<Task>> _tasksFuture;

  String? _selectedType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedAssigneeId;

  final TextEditingController _searchController =
  TextEditingController();

  String _typeLabel(String? type) {
    switch (type) {
      case 'created':
        return 'Đã tạo';
      case 'assigned':
        return 'Được giao';
      case 'accepted':
        return 'Đã nhận';
      case 'shared':
        return 'Được chia sẻ';
      default:
        return 'Tất cả';
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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    _tasksFuture = _taskService.fetchTasks(
      type: _selectedType,
    );
  }

  Future<void> _reloadTasks() async {
    setState(() {
      _loadTasks();
    });

    await _tasksFuture;
  }

  Future<void> _openCreateTaskScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskCreateScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _reloadTasks();
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (!mounted || shouldLogout != true) return;

    await AuthService().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> _openTaskDetail(Task task) async {
    await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );

    if (!mounted) return;

    await _reloadTasks();
  }

  // Mở bảng bộ lọc công việc
  Future<void> _openFilterSheet() async {
    final tasks = await _tasksFuture;

    if (!mounted) return;

    // Lấy danh sách người phụ trách
    final assignees = <String, TaskAssignee>{};

    for (final task in tasks) {
      for (final assignee in task.assignees) {
        if (assignee.id.isNotEmpty) {
          assignees[assignee.id] = assignee;
        }
      }
    }

    // Các lựa chọn tạm thời trong bảng lọc
    String? draftType = _selectedType;
    String? draftStatus = _selectedStatus;
    String? draftPriority = _selectedPriority;

    String? draftAssigneeId =
    assignees.containsKey(_selectedAssigneeId)
        ? _selectedAssigneeId
        : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bộ lọc công việc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lọc theo loại công việc
                      DropdownButtonFormField<String?>(
                        initialValue: draftType,
                        decoration: const InputDecoration(
                          labelText: 'Loại công việc',
                          prefixIcon: Icon(Icons.folder_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'created',
                            child: Text('Đã tạo'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'assigned',
                            child: Text('Được giao'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'accepted',
                            child: Text('Đã nhận'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'shared',
                            child: Text('Được chia sẻ'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Lọc theo trạng thái
                      DropdownButtonFormField<String?>(
                        initialValue: draftStatus,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          prefixIcon: Icon(
                            Icons.check_circle_outline,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tất cả trạng thái'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'not_started',
                            child: Text('Chưa thực hiện'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'in_progress',
                            child: Text('Đang thực hiện'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'completed',
                            child: Text('Đã hoàn thành'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Lọc theo mức độ ưu tiên
                      DropdownButtonFormField<String?>(
                        initialValue: draftPriority,
                        decoration: const InputDecoration(
                          labelText: 'Mức độ ưu tiên',
                          prefixIcon: Icon(Icons.flag_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Tất cả mức độ ưu tiên',
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'low',
                            child: Text('Thấp'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'medium',
                            child: Text('Trung bình'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'high',
                            child: Text('Cao'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftPriority = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Lọc theo người phụ trách
                      DropdownButtonFormField<String?>(
                        initialValue: draftAssigneeId,
                        decoration: const InputDecoration(
                          labelText: 'Người phụ trách',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Tất cả người phụ trách',
                            ),
                          ),
                          ...assignees.values.map(
                                (assignee) => DropdownMenuItem<String?>(
                              value: assignee.id,
                              child: Text(
                                assignee.fullName.isEmpty
                                    ? assignee.email
                                    : assignee.fullName,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftAssigneeId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Nút áp dụng bộ lọc
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedType = draftType;
                              _selectedStatus = draftStatus;
                              _selectedPriority = draftPriority;
                              _selectedAssigneeId =
                                  draftAssigneeId;

                              _loadTasks();
                            });

                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Áp dụng bộ lọc'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Nút xóa tất cả bộ lọc
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              draftType = null;
                              draftStatus = null;
                              draftPriority = null;
                              draftAssigneeId = null;
                            });
                          },
                          child: const Text('Xóa tất cả bộ lọc'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Thông tin cá nhân',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _confirmLogout,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskScreen,
        tooltip: 'Tạo công việc',
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // Ô tìm kiếm và biểu tượng bộ lọc
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm theo tên công việc',
                      hintText: 'Nhập tên công việc...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: _openFilterSheet,
                  tooltip: 'Bộ lọc công việc',
                  icon: const Icon(
                    Icons.filter_list,
                    size: 30,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    fixedSize: const Size(52, 52),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách công việc
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
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
                          const Text(
                            'Không thể tải công việc.',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loadTasks();
                              });
                            },
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];

                // Lấy danh sách người phụ trách
                final assignees = <String, TaskAssignee>{};

                for (final task in allTasks) {
                  for (final assignee in task.assignees) {
                    if (assignee.id.isNotEmpty) {
                      assignees[assignee.id] = assignee;
                    }
                  }
                }

                // Kiểm tra người phụ trách còn tồn tại
                final selectedAssigneeId =
                assignees.containsKey(_selectedAssigneeId)
                    ? _selectedAssigneeId
                    : null;

                // Tìm kiếm theo tên
                final keyword =
                _searchController.text.trim().toLowerCase();

                // Kết hợp tất cả điều kiện lọc
                final tasks = allTasks.where((task) {
                  final matchesName = task.title
                      .toLowerCase()
                      .contains(keyword);

                  final matchesStatus =
                      _selectedStatus == null ||
                          task.status == _selectedStatus;

                  final matchesPriority =
                      _selectedPriority == null ||
                          task.priority == _selectedPriority;

                  final matchesAssignee =
                      selectedAssigneeId == null ||
                          task.assignedTo.contains(
                            selectedAssigneeId,
                          );

                  return matchesName &&
                      matchesStatus &&
                      matchesPriority &&
                      matchesAssignee;
                }).toList();

                // Hiển thị danh sách kết quả
                return tasks.isEmpty
                    ? RefreshIndicator(
                  onRefresh: _reloadTasks,
                  child: ListView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          allTasks.isEmpty
                              ? 'Chưa có công việc nào.'
                              : 'Không tìm thấy công việc phù hợp.',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Danh mục: ${_typeLabel(_selectedType)}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Kéo xuống để tải lại.',
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _reloadTasks,
                  child: ListView.builder(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          onTap: () {
                            _openTaskDetail(task);
                          },
                          leading: Icon(
                            _getStatusIcon(task.status),
                            color: _getStatusColor(
                              task.status,
                            ),
                            size: 30,
                          ),
                          title: Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                task.description.isEmpty
                                    ? 'Không có mô tả'
                                    : task.description,
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 16,
                                    color: _getPriorityColor(
                                      task.priority,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ưu tiên: ${_getPriorityLabel(task.priority)}',
                                    style: TextStyle(
                                      color:
                                      _getPriorityColor(
                                        task.priority,
                                      ),
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            _getStatusLabel(task.status),
                            style: TextStyle(
                              color: _getStatusColor(
                                task.status,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
