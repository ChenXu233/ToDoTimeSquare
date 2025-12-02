enum TodoImportance { low, medium, high }

class Todo {
  final String id;
  final String title;
  final String? description;
  final Duration? estimatedDuration;
  final TodoImportance importance;
  final DateTime? plannedStartTime;
  bool isCompleted;
  final String? parentId;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.estimatedDuration,
    this.importance = TodoImportance.medium,
    this.plannedStartTime,
    this.isCompleted = false,
    this.parentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'estimatedDuration': estimatedDuration?.inMicroseconds,
      'importance': importance.index,
      'plannedStartTime': plannedStartTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'parentId': parentId,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(microseconds: json['estimatedDuration'])
          : null,
      importance: TodoImportance.values[json['importance'] ?? 1],
      plannedStartTime: json['plannedStartTime'] != null
          ? DateTime.parse(json['plannedStartTime'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      parentId: json['parentId'],
    );
  }
}
