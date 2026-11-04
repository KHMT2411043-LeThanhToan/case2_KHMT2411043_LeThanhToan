
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
  State<TaskListScreen> createState() =>
      _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();

  late Future<List<Task>> _tasksFuture;

  String? _selectedType;

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

  // Lấy tên trạng thái công việc
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

  // Lấy biểu tượng trạng thái
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

  // Lấy màu trạng thái
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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Tải danh sách công việc
  void _loadTasks() {
    _tasksFuture = _taskService.fetchTasks(
      type: _selectedType,
    );
  }

  // Thay đổi bộ lọc
  void _changeType(String? type) {
    setState(() {
      _selectedType = type;
      _loadTasks();
    });
  }

  // Tải lại danh sách công việc
  Future<void> _reloadTasks() async {
    setState(() {
      _loadTasks();
    });

    await _tasksFuture;
  }

  // Mở màn hình tạo công việc
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

  // Xác nhận đăng xuất
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

  // Mở chi tiết và tải lại danh sách khi quay về
  Future<void> _openTaskDetail(Task task) async {
    await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );

    if (!mounted) return;

    // Luôn tải lại dữ liệu mới nhất từ Backend
    await _reloadTasks();
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

      // Nút tạo công việc
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskScreen,
        tooltip: 'Tạo công việc',
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // Bộ lọc công việc
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Lọc công việc',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
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
              onChanged: _changeType,
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

                final tasks = snapshot.data ?? [];

                // Không có công việc
                if (tasks.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reloadTasks,
                    child: ListView(
                      physics:
                      const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Chưa có công việc nào.',
                            style: TextStyle(fontSize: 16),
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
                  );
                }

                // Hiển thị danh sách
                return RefreshIndicator(
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
                            color: _getStatusColor(task.status),
                            size: 30,
                          ),
                          title: Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: task.description.isEmpty
                              ? const Text('Không có mô tả')
                              : Text(task.description),
                          trailing: Text(
                            _getStatusLabel(task.status),
                            style: TextStyle(
                              color: _getStatusColor(task.status),
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
