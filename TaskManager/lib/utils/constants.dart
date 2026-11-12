
class TaskStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';

  static const List<String> values = [
    notStarted,
    inProgress,
    completed,
  ];

  static const Map<String, String> labels = {
    notStarted: 'Chưa thực hiện',
    inProgress: 'Đang thực hiện',
    completed: 'Đã hoàn thành',
  };
}

class TaskPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';

  static const List<String> values = [
    low,
    medium,
    high,
  ];

  static const Map<String, String> labels = {
    low: 'Thấp',
    medium: 'Trung bình',
    high: 'Cao',
  };

  static const Map<String, int> sortOrder = {
    low: 1,
    medium: 2,
    high: 3,
  };
}

class TaskType {
  static const String created = 'created';
  static const String assigned = 'assigned';
  static const String accepted = 'accepted';
  static const String shared = 'shared';

  static const Map<String, String> labels = {
    created: 'Đã tạo',
    assigned: 'Được giao',
    accepted: 'Đã nhận',
    shared: 'Được chia sẻ',
  };
}

class TaskSortBy {
  static const String dueDate = 'dueDate';
  static const String priority = 'priority';
  static const String createdAt = 'createdAt';

  static const List<String> values = [
    dueDate,
    priority,
    createdAt,
  ];
}
