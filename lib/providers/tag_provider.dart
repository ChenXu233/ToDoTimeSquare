import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/database/app_database.dart';
import '../models/database/database_initializer.dart';
import '../models/database/schema/task_tags.dart';
import '../models/entities/task_tag_model.dart';
import '../models/repositories/task_tag_repository.dart';

/// 标签状态管理
/// 提供标签的全局状态和操作方法
class TagProvider with ChangeNotifier {
  final AppDatabase db;
  TaskTagRepository? _repository;
  List<TaskTagEntity> _allTags = [];
  List<TaskTagEntity> _filteredTags = [];
  bool _isLoading = false;
  String _searchQuery = '';
  TagType? _filterType;

  TagProvider() : db = DatabaseInitializer().database;

  TaskTagRepository get _repo {
    _repository ??= TaskTagRepository(db);
    return _repository!;
  }

  // ========== Getter ==========

  /// 所有标签
  List<TaskTagEntity> get allTags => _allTags;

  /// 过滤后的标签
  List<TaskTagEntity> get filteredTags => _filteredTags;

  /// 是否加载中
  bool get isLoading => _isLoading;

  /// 搜索关键词
  String get searchQuery => _searchQuery;

  /// 当前过滤类型
  TagType? get filterType => _filterType;

  /// 按类型分组的标签
  Map<TagType, List<TaskTagEntity>> get tagsByType {
    final Map<TagType, List<TaskTagEntity>> grouped = {};
    for (final tag in _allTags) {
      grouped.putIfAbsent(tag.type, () => []).add(tag);
    }
    return grouped;
  }

  /// 常用标签
  List<TaskTagEntity> get frequentlyUsedTags {
    return [..._allTags]
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  // ========== 加载方法 ==========

  /// 加载所有标签
  Future<void> loadTags() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allTags = await _repo.getAllTags();
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新标签
  Future<void> refreshTags() async {
    await loadTags();
  }

  // ========== 筛选方法 ==========

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// 设置类型过滤
  void setFilterType(TagType? type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  /// 清除筛选
  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _filteredTags = _allTags;
    notifyListeners();
  }

  void _applyFilters() {
    var tags = [..._allTags];

    // 类型过滤
    if (_filterType != null) {
      tags = tags.where((t) => t.type == _filterType).toList();
    }

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tags = tags
          .where((t) =>
              t.name.toLowerCase().contains(query) ||
              TaskTagEntity.typeNames[t.type]!.toLowerCase().contains(query))
          .toList();
    }

    _filteredTags = tags;
  }

  // ========== CRUD 操作 ==========

  /// 创建标签
  Future<TaskTagEntity> createTag({
    required String name,
    required String color,
    required TagType type,
    String? icon,
    bool isPreset = false,
  }) async {
    final tag = TaskTagEntity(
      id: 'tag_${DateTime.now().millisecondsSinceEpoch}_${_allTags.length}',
      userId: 'local',
      name: name,
      color: color,
      type: type,
      icon: icon,
      isPreset: isPreset,
      usageCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.createTag(tag);
    await loadTags();
    return tag;
  }

  /// 更新标签
  Future<bool> updateTag(TaskTagEntity tag) async {
    final result = await _repo.updateTag(tag);
    if (result) {
      await loadTags();
    }
    return result;
  }

  /// 删除标签
  Future<void> deleteTag(String id) async {
    await _repo.deleteTag(id);
    await loadTags();
  }

  // ========== 任务标签操作 ==========

  /// 获取任务的标签
  Future<List<TaskTagEntity>> getTagsForTask(String todoId) async {
    return await _repo.getTagsForTask(todoId);
  }

  /// 为任务添加标签
  Future<void> addTagToTask(String todoId, String tagId) async {
    await _repo.addTagToTask(todoId, tagId);
  }

  /// 为任务移除标签
  Future<void> removeTagFromTask(String todoId, String tagId) async {
    await _repo.removeTagFromTask(todoId, tagId);
  }

  /// 设置任务的标签
  Future<void> setTagsForTask(String todoId, List<String> tagIds) async {
    await _repo.setTagsForTask(todoId, tagIds);
  }

  /// 删除任务的关联标签（任务删除时调用）
  Future<void> deleteRelationsForTask(String todoId) async {
    await _repo.deleteTaskTagRelationsByTodoId(todoId);
  }

  // ========== 统计方法 ==========

  /// 获取标签使用次数
  Future<int> getTagUsageCount(String tagId) async {
    return await _repo.getTaggedTaskCount(tagId);
  }

  /// 搜索标签
  Future<List<TaskTagEntity>> searchTags(String query) async {
    return await _repo.searchTags(query);
  }
}
