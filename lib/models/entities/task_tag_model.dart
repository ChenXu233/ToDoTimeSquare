import 'package:flutter/material.dart';
import '../database/schema/task_tags.dart';

/// 标签数据模型（领域实体）
class TaskTagEntity {
  final String id;
  final String userId;
  final String name;
  final String color;
  final TagType type;
  final String? icon;
  final bool isPreset;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskTagEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.type,
    this.icon,
    this.isPreset = false,
    this.usageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 复制
  TaskTagEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    TagType? type,
    String? icon,
    bool? isPreset,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskTagEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isPreset: isPreset ?? this.isPreset,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 预设标签颜色
  static const presetColors = [
    '#F44336', // 红
    '#E91E63', // 粉
    '#9C27B0', // 紫
    '#673AB7', // 深紫
    '#3F51B5', // 蓝
    '#2196F3', // 浅蓝
    '#03A9F4', // 天蓝
    '#00BCD4', // 青
    '#009688', // 青绿
    '#4CAF50', // 绿
    '#8BC34A', // 浅绿
    '#CDDC39', // 黄绿
    '#FFC107', // 琥珀
    '#FF9800', // 橙
    '#FF5722', // 深橙
    '#795548', // 棕
  ];

  /// 预设标签类型名称
  static const typeNames = {
    TagType.color: '颜色',
    TagType.project: '项目',
    TagType.context: '场景',
    TagType.custom: '自定义',
  };
}

/// 任务标签关联模型（领域实体）
class TaskTagRelationEntity {
  final String id;
  final String todoId;
  final String tagId;
  final DateTime createdAt;

  TaskTagRelationEntity({
    required this.id,
    required this.todoId,
    required this.tagId,
    required this.createdAt,
  });
}

/// 带标签的任务模型扩展
class TaskWithTags {
  final String id;
  final String title;
  final String? description;
  final int? estimatedDuration;
  final int importance;
  final DateTime? plannedStartTime;
  final bool isCompleted;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<TaskTagEntity> tags;

  TaskWithTags({
    required this.id,
    required this.title,
    this.description,
    this.estimatedDuration,
    required this.importance,
    this.plannedStartTime,
    required this.isCompleted,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.tags = const [],
  });
}

/// 颜色工具类
class TagColorUtils {
  /// 预设颜色列表
  static const List<String> presetColors = [
    '#F44336', // 红
    '#E91E63', // 粉
    '#9C27B0', // 紫
    '#673AB7', // 深紫
    '#3F51B5', // 蓝
    '#2196F3', // 浅蓝
    '#03A9F4', // 天蓝
    '#00BCD4', // 青
    '#009688', // 青绿
    '#4CAF50', // 绿
    '#8BC34A', // 浅绿
    '#CDDC39', // 黄绿
    '#FFC107', // 琥珀
    '#FF9800', // 橙
    '#FF5722', // 深橙
    '#795548', // 棕
    '#607D8B', // 蓝灰
    '#9E9E9E', // 灰
  ];

  /// 从 Hex 字符串创建 Color
  static Color fromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    } else if (hex.length == 8) {
      return Color(int.parse('0x$hex'));
    }
    return const Color(0xFF2196F3);
  }

  /// 获取随机颜色
  static String getRandomColor() {
    return presetColors[
        DateTime.now().millisecondsSinceEpoch % presetColors.length];
  }
}
