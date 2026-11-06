
class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String createdBy;
  final List<String> assignedTo;
  final List<String> acceptedBy;
  final List<String> sharedWith;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.status = 'not_started',
    this.priority = 'medium',
    this.startDate,
    this.dueDate,
    this.createdBy = '',
    this.assignedTo = const [],
    this.acceptedBy = const [],
    this.sharedWith = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    List<String> parseIds(dynamic value) {
      if (value is! List) return [];

      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return item['_id']?.toString() ?? '';
        }

        return item.toString();
      }).where((id) => id.isNotEmpty).toList();
    }

    return Task(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_started',
      priority: json['priority']?.toString() ?? 'medium',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())?.toLocal()
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())?.toLocal()
          : null,
      createdBy: json['createdBy']?.toString() ?? '',
      assignedTo: parseIds(json['assignedTo']),
      acceptedBy: parseIds(json['acceptedBy']),
      sharedWith: parseIds(json['sharedWith']),
    );
  }
}
