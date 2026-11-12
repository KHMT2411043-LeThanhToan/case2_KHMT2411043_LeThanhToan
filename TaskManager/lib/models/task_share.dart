
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
