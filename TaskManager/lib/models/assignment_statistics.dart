
class AssignmentStatistics {
  final int assigned;
  final int responsible;

  AssignmentStatistics({
    required this.assigned,
    required this.responsible,
  });

  factory AssignmentStatistics.fromJson(
      Map<String, dynamic> json,
      ) {
    return AssignmentStatistics(
      assigned: json['assigned'] ?? 0,
      responsible: json['responsible'] ?? 0,
    );
  }
}
