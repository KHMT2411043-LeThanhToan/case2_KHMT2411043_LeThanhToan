
class TaskProgress {
  final String userId;
  final String fullName;
  final String email;
  final String status;
  final DateTime? updatedAt;

  const TaskProgress({
    required this.userId,
    this.fullName = '',
    this.email = '',
    this.status = 'not_started',
    this.updatedAt,
  });

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];

    if (userData is Map<String, dynamic>) {
      return TaskProgress(
        userId: userData['_id']?.toString() ?? '',
        fullName: userData['fullName']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        status: json['status']?.toString() ?? 'not_started',
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
            : null,
      );
    }

    return TaskProgress(
      userId: userData?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_started',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
    );
  }
}
