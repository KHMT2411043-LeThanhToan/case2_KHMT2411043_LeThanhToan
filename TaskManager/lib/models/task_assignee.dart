
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
