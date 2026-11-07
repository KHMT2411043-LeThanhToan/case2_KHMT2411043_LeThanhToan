
class TaskAssignee {
  final String id;
  final String fullName;
  final String email;

  const TaskAssignee({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory TaskAssignee.fromJson(Map<String, dynamic> json) {
    return TaskAssignee(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

// Model luu thong tin nguoi duoc chia se va quyen cua ho
class TaskShare {
  final String userId;
  final String fullName;
  final String email;
  final String permission;

  const TaskShare({
    required this.userId,
    this.fullName = '',
    this.email = '',
    this.permission = 'viewer',
  });

  factory TaskShare.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];

    if (userData is Map<String, dynamic>) {
      return TaskShare(
        userId: userData['_id']?.toString() ?? '',
        fullName: userData['fullName']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        permission: json['permission']?.toString() ?? 'viewer',
      );
    }

    return TaskShare(
      userId: userData?.toString() ?? '',
      permission: json['permission']?.toString() ?? 'viewer',
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String createdBy;
  final List<String> assignedTo;
  final List<TaskAssignee> assignees;
  final TaskAssignee? primaryAssignee;
  final List<String> acceptedBy;
  final List<String> sharedWith;
  final List<TaskShare> sharedPermissions;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.status = 'not_started',
    this.priority = 'medium',
    this.startDate,
    this.dueDate,
    this.createdAt,
    this.createdBy = '',
    this.assignedTo = const [],
    this.assignees = const [],
    this.primaryAssignee,
    this.acceptedBy = const [],
    this.sharedWith = const [],
    this.sharedPermissions = const [],
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

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,

      createdBy: json['createdBy']?.toString() ?? '',

      assignedTo: parseIds(json['assignedTo']),

      assignees: json['assignedTo'] is List
          ? (json['assignedTo'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => TaskAssignee.fromJson(item))
          .toList()
          : [],

      primaryAssignee:
      json['primaryAssigneeId'] is Map<String, dynamic>
          ? TaskAssignee.fromJson(
        json['primaryAssigneeId'] as Map<String, dynamic>,
      )
          : null,

      acceptedBy: parseIds(json['acceptedBy']),
      sharedWith: parseIds(json['sharedWith']),

      // Nguoi duoc chia se cu chua co quyen mac dinh la viewer
      sharedPermissions: json['sharedPermissions'] is List
          ? (json['sharedPermissions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => TaskShare.fromJson(item))
          .toList()
          : [],
    );
  }
}
