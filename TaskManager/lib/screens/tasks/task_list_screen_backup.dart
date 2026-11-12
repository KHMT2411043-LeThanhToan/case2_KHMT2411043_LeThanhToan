
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/task_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_screen.dart';
import 'task_detail_screen.dart';
import 'task_create_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService =
  NotificationService();

  late Future<List<Task>> _tasksFuture;
  late Future<int> _unreadCountFuture;

  String? _selectedType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedAssigneeId;

  // Tiêu chí sắp xếp
  String _sortBy = 'createdAt';

  // Thứ tự sắp xếp: true = tăng dần
  bool _ascending = false;

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

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadUnreadCount();
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

  void _loadUnreadCount() {
    _unreadCountFuture =
        _notificationService.fetchUnreadCount().catchError(
              (error) {
            return 0;
          },
        );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _loadUnreadCount();
    });
  }

  Future<void> _reloadTasks() async {
    setState(() {
      _loadTasks();
    });

    await _tasksFuture;
  }

  void _sortTasks(List<Task> tasks) {
    tasks.sort((a, b) {
      int result = 0;

      if (_sortBy == 'dueDate') {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;

        result = a.dueDate!.compareTo(b.dueDate!);
      } else if (_sortBy == 'priority') {
        const priorityOrder = {
          'low': 1,
          'medium': 2,
          'high': 3,
        };

        result = (priorityOrder[a.priority] ?? 2)
            .compareTo(priorityOrder[b.priority] ?? 2);
      } else {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;

        result = a.createdAt!.compareTo(b.createdAt!);
      }

      return _ascending ? result : -result;
    });
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
                                (assignee) =>
                                DropdownMenuItem<String?>(
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

  // Mở bảng sắp xếp công việc
  Future<void> _openSortSheet() async {
    String draftSortBy = _sortBy;
    bool draftAscending = _ascending;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sắp xếp công việc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: draftSortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sắp xếp theo',
                        prefixIcon: Icon(Icons.sort),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'dueDate',
                          child: Text('Hạn hoàn thành'),
                        ),
                        DropdownMenuItem(
                          value: 'priority',
                          child: Text('Mức độ ưu tiên'),
                        ),
                        DropdownMenuItem(
                          value: 'createdAt',
                          child: Text('Thời gian tạo'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            draftSortBy = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<bool>(
                      initialValue: draftAscending,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự',
                        prefixIcon: Icon(Icons.swap_vert),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Tăng dần'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Giảm dần'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            draftAscending = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _sortBy = draftSortBy;
                            _ascending = draftAscending;
                          });

                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Áp dụng sắp xếp'),
                      ),
                    ),
                  ],
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
          // Chuông thông báo và số thông báo chưa đọc
          FutureBuilder<int>(
            future: _unreadCountFuture,
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return IconButton(
                tooltip: 'Thông báo',
                onPressed: _openNotifications,
                icon: SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        size: 27,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : unreadCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

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

                // Nút lọc công việc
                IconButton(
                  onPressed: _openFilterSheet,
                  tooltip: 'Bộ lọc công việc',
                  icon: const Icon(
                    Icons.filter_list,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    fixedSize: const Size(48, 52),
                  ),
                ),

                const SizedBox(width: 4),

                // Nút sắp xếp công việc
                IconButton(
                  onPressed: _openSortSheet,
                  tooltip: 'Sắp xếp công việc',
                  icon: const Icon(
                    Icons.sort,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade800,
                    fixedSize: const Size(48, 52),
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

                // Sắp xếp danh sách công việc
                _sortTasks(tasks);

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

                      return TaskCard(
                        task: task,
                        onTap: () {
                          _openTaskDetail(task);
                        },
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
