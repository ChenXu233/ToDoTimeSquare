import 'dart:convert';

class FocusRecord {
  final String id;
  final DateTime startTime;
  final int durationSeconds;
  final String? taskId;
  final String? taskTitle;
  final bool isSynced;
  final DateTime createdAt;

  FocusRecord({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    this.taskId,
    this.taskTitle,
    this.isSynced = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FocusRecord.fromMap(Map<String, dynamic> map) {
    return FocusRecord(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      durationSeconds: map['durationSeconds'],
      taskId: map['taskId'],
      taskTitle: map['taskTitle'],
      isSynced: map['isSynced'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory FocusRecord.fromJson(String source) =>
      FocusRecord.fromMap(json.decode(source));
}
