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
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.estimatedDuration,
    this.importance = TodoImportance.medium,
    this.plannedStartTime,
    this.isCompleted = false,
    this.parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}
