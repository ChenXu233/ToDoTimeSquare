enum TodoImportance { low, medium, high }

class Todo {
  final String id;
  final String title;
  final String? description;
  final Duration? estimatedDuration;
  final TodoImportance importance;
  final DateTime? plannedStartTime;
  bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.estimatedDuration,
    this.importance = TodoImportance.medium,
    this.plannedStartTime,
    this.isCompleted = false,
  });
}
