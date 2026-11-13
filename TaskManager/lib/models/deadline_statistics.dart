
class DeadlineTask {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? dueDate;

  DeadlineTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
  });

  factory DeadlineTask.fromJson(Map<String, dynamic> json) {
    return DeadlineTask(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'not_started',
      priority: json['priority'] ?? 'medium',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
    );
  }
}

class DeadlineStatistics {
  final List<DeadlineTask> upcomingTasks;
  final List<DeadlineTask> overdueTasks;

  DeadlineStatistics({
    required this.upcomingTasks,
    required this.overdueTasks,
  });

  int get upcomingCount => upcomingTasks.length;

  int get overdueCount => overdueTasks.length;

  factory DeadlineStatistics.fromJson(Map<String, dynamic> json) {
    return DeadlineStatistics(
      upcomingTasks: (json['upcomingTasks'] as List? ?? [])
          .map((item) => DeadlineTask.fromJson(
        Map<String, dynamic>.from(item),
      ))
          .toList(),
      overdueTasks: (json['overdueTasks'] as List? ?? [])
          .map((item) => DeadlineTask.fromJson(
        Map<String, dynamic>.from(item),
      ))
          .toList(),
    );
  }
}
