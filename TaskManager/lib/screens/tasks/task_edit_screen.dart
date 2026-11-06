
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

  DateTime? _startDate;
  DateTime? _dueDate;

  bool _isLoading = false;
// Ham mo lich chon ngay
  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime firstSelectableDate = isStartDate
        ? DateTime(2000)
        : (_startDate ?? DateTime(2000));

    final DateTime initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_dueDate ?? _startDate ?? DateTime.now());

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(2100),
      helpText: isStartDate
          ? 'Chọn ngày bắt đầu'
          : 'Chọn hạn hoàn thành',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = pickedDate;

        if (_dueDate != null && _dueDate!.isBefore(pickedDate)) {
          _dueDate = null;
        }
      } else {
        _dueDate = pickedDate;
      }
    });
  }
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
    _startDate = widget.task.startDate;
    _dueDate = widget.task.dueDate;
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
        startDate: _startDate,
        dueDate: _dueDate,
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

              const SizedBox(height: 16),

// Chon ngay bat dau
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Ngày bắt đầu'),
                subtitle: Text(
                  _startDate == null
                      ? 'Chưa chọn ngày'
                      : '${_startDate!.day.toString().padLeft(2, '0')}/'
                      '${_startDate!.month.toString().padLeft(2, '0')}/'
                      '${_startDate!.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _isLoading
                      ? null
                      : () => _selectDate(isStartDate: true),
                ),
              ),

// Chon han hoan thanh
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Hạn hoàn thành'),
                subtitle: Text(
                  _dueDate == null
                      ? 'Chưa chọn ngày'
                      : '${_dueDate!.day.toString().padLeft(2, '0')}/'
                      '${_dueDate!.month.toString().padLeft(2, '0')}/'
                      '${_dueDate!.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _isLoading
                      ? null
                      : () => _selectDate(isStartDate: false),
                ),
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
