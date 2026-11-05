
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskEditScreen extends StatefulWidget {
  final Task task;

  const TaskEditScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  final TaskService _taskService = TaskService();

  late String _selectedStatus;
  late String _selectedPriority;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.task.title,
    );

    _descriptionController = TextEditingController(
      text: widget.task.description,
    );

    _selectedStatus = [
      'not_started',
      'in_progress',
      'completed',
    ].contains(widget.task.status)
        ? widget.task.status
        : 'not_started';

    _selectedPriority = [
      'low',
      'medium',
      'high',
    ].contains(widget.task.priority)
        ? widget.task.priority
        : 'medium';
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = await _taskService.updateTask(
        taskId: widget.task.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật công việc thành công!'),
        ),
      );

      Navigator.pop(context, updatedTask);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề công việc',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề công việc.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả công việc',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              // Chon trang thai cong viec
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái công việc',
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
                onChanged: _isLoading
                    ? null
                    : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Chon muc do uu tien
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
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
                onChanged: _isLoading
                    ? null
                    : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateTask,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
