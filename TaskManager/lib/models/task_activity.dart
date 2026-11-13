
class TaskActivity {
  final String id;
  final String taskId;
  final String userName;
  final String action;
  final String description;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.userName,
    required this.action,
    required this.description,
    this.changes,
    required this.createdAt,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    return TaskActivity(
      id: json['_id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      userName: json['userId'] is Map
          ? json['userId']['fullName']?.toString() ?? 'Người dùng'
          : 'Người dùng',
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      changes: json['changes'] is Map
          ? Map<String, dynamic>.from(json['changes'])
          : null,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }
}
