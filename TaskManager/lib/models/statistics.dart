
class Statistics {
  final int notStarted;
  final int inProgress;
  final int completed;
  final int total;

  Statistics({
    required this.notStarted,
    required this.inProgress,
    required this.completed,
    required this.total,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      notStarted: json['not_started'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}
