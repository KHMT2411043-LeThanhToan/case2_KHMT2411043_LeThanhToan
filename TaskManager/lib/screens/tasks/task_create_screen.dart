
import 'package:flutter/material.dart';

import '../../services/task_service.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() =>
      _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final TaskService _taskService = TaskService();

  String _selectedPriority = 'medium';

  bool _isLoading = false;

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo công việc thành công!'),
        ),
      );

      Navigator.pop(context, true);
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
        title: const Text('Tạo công việc'),
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
                  onPressed: _isLoading ? null : _createTask,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Tạo công việc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
