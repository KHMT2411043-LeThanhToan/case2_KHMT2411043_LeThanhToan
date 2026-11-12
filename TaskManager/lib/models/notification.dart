
class AppNotification {
  final String id;
  final String senderName;
  final String senderEmail;
  final String? taskId;
  final String taskTitle;
  final String type;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.senderName = '',
    this.senderEmail = '',
    this.taskId,
    this.taskTitle = '',
    required this.type,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final task = json['task'];

    return AppNotification(
      id: json['_id']?.toString() ?? '',
      senderName: sender is Map
          ? sender['fullName']?.toString() ?? ''
          : '',
      senderEmail: sender is Map
          ? sender['email']?.toString() ?? ''
          : '',
      taskId: task is Map
          ? task['_id']?.toString()
          : task?.toString(),
      taskTitle: task is Map
          ? task['title']?.toString() ?? ''
          : '',
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )?.toLocal()
          : null,
    );
  }
}
