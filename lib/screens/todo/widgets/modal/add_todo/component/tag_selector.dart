import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ToDoTimeSquare/providers/tag_provider.dart';
import 'package:ToDoTimeSquare/models/entities/task_tag_model.dart';
import 'package:ToDoTimeSquare/models/database/schema/task_tags.dart';
import 'package:ToDoTimeSquare/i18n/i18n.dart';
import 'package:ToDoTimeSquare/widgets/glass/glass_container.dart';

/// 标签选择器组件
/// 支持内联小面板（标签少）和 BottomSheet 弹窗（标签多）
class TagSelector extends StatefulWidget {
  /// 当前选中的标签 ID 列表
  final List<String> selectedTagIds;

  /// 标签变化回调
  final ValueChanged<List<String>> onTagsChanged;

  /// 最大显示标签数量
  final int maxVisibleTags;

  /// 内联面板阈值（超过此数量使用 BottomSheet）
  final int inlinePanelThreshold;

  const TagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.maxVisibleTags = 3,
    this.inlinePanelThreshold = 12,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        final allTags = tagProvider.allTags;

        // 一次性遍历分离已选和未选标签
        final selectedTags = <TaskTagEntity>[];
        final availableTags = <TaskTagEntity>[];
        for (final tag in allTags) {
          if (widget.selectedTagIds.contains(tag.id)) {
            if (selectedTags.length < widget.maxVisibleTags) {
              selectedTags.add(tag);
            }
          } else {
            availableTags.add(tag);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示已选标签
            if (selectedTags.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    i18n.tags,
                    style: TextStyle(
                      color: textColor.withAlpha(((0.7) * 255).round()),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTags.map((tag) {
                  return _buildTagChip(
                    tag,
                    isSelected: true,
                    colorScheme: colorScheme,
                    textColor: textColor,
                    onTap: () => _removeTag(tag.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 标签选择行
            GestureDetector(
              onTap: () => _handleTagSelectorTap(context, allTags.length),
              child: GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: BorderRadius.circular(8),
                opacity: 0.3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: textColor.withAlpha(((0.7) * 255).round()),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedTags.isEmpty
                          ? i18n.addTags
                          : '${i18n.addTags} (${allTags.length})',
                      style: TextStyle(
                        color: textColor.withAlpha(((0.7) * 255).round()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: textColor.withAlpha(((0.7) * 255).round()),
                    ),
                  ],
                ),
              ),
            ),

            // 展开的内联标签选择面板（仅标签少时使用）
            if (_isExpanded && _canUseInlinePanel(availableTags.length))
              _buildInlinePanel(
                context,
                allTags,
                availableTags,
                colorScheme,
                textColor,
                i18n,
              ),
          ],
        );
      },
    );
  }

  /// 判断是否使用内联面板
  bool _canUseInlinePanel(int availableTagCount) {
    return availableTagCount <= widget.inlinePanelThreshold;
  }

  /// 处理标签选择器点击
  void _handleTagSelectorTap(BuildContext context, int totalTagCount) {
    if (totalTagCount > widget.inlinePanelThreshold) {
      // 标签多，使用 BottomSheet
      _showTagBottomSheet(context);
    } else {
      // 标签少，使用内联面板
      setState(() {
        _isExpanded = !_isExpanded;
      });
      if (_isExpanded) {
        _focusNode.requestFocus();
      }
    }
  }

  /// 显示标签选择 BottomSheet
  void _showTagBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          color: colorScheme.surface.withValues(alpha: 0.95),
        ),
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          opacity: 0.7,
          child: _buildBottomSheetContent(context),
        ),
      ),
    );
  }

  /// 构建 BottomSheet 内容
  Widget _buildBottomSheetContent(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        final allTags = tagProvider.allTags;
        final availableTags = allTags
            .where((tag) => !widget.selectedTagIds.contains(tag.id))
            .toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动把手
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withAlpha(((0.3) * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i18n.addTags,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: textColor.withAlpha(((0.7) * 255).round()),
                    ),
                  ),
                ],
              ),
            ),

            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: i18n.searchTags,
                  hintStyle: TextStyle(
                    color: textColor.withAlpha(((0.5) * 255).round()),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: textColor.withAlpha(((0.5) * 255).round()),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: textColor.withAlpha(((0.5) * 255).round()),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            tagProvider.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surface.withAlpha(((0.5) * 255).round()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  tagProvider.setSearchQuery(value);
                },
              ),
            ),

            const SizedBox(height: 12),

            // 类型筛选（横向滚动）
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTypeFilterChip(
                    null,
                    i18n.all,
                    colorScheme,
                    textColor,
                  ),
                  ...TagType.values.map((type) {
                    return _buildTypeFilterChip(
                      type,
                      TaskTagEntity.typeNames[type] ?? type.name,
                      colorScheme,
                      textColor,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 标签列表
            if (availableTags.isEmpty && allTags.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    i18n.noTagsAvailable,
                    style: TextStyle(
                      color: textColor.withAlpha(((0.5) * 255).round()),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else if (allTags.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i18n.noTagsYet,
                        style: TextStyle(
                          color: textColor.withAlpha(((0.5) * 255).round()),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: 跳转到标签管理页面
                        },
                        icon: const Icon(Icons.add),
                        label: Text(i18n.createTag),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      return _buildTagChip(
                        tag,
                        isSelected: false,
                        colorScheme: colorScheme,
                        textColor: textColor,
                        onTap: () {
                          _addTag(tag.id);
                          // 如果是 BottomSheet 模式，关闭弹窗
                          if (!_canUseInlinePanel(availableTags.length)) {
                            Navigator.pop(context);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

            // 底部操作栏
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + bottomPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(i18n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(i18n.confirm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建内联面板（小标签数量时使用）
  Widget _buildInlinePanel(
    BuildContext context,
    List<TaskTagEntity> allTags,
    List<TaskTagEntity> availableTags,
    ColorScheme colorScheme,
    Color textColor,
    APPi18n i18n,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: i18n.searchTags,
              hintStyle: TextStyle(
                color: textColor.withAlpha(((0.5) * 255).round()),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: textColor.withAlpha(((0.5) * 255).round()),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: textColor.withAlpha(((0.5) * 255).round()),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<TagProvider>().setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surface.withAlpha(((0.5) * 255).round()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              context.read<TagProvider>().setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),

          // 类型筛选（横向滚动）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip(
                  null,
                  i18n.all,
                  colorScheme,
                  textColor,
                ),
                ...TagType.values.map((type) {
                  return _buildTypeFilterChip(
                    type,
                    TaskTagEntity.typeNames[type] ?? type.name,
                    colorScheme,
                    textColor,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 标签列表（自适应高度）
          if (availableTags.isEmpty && allTags.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  i18n.noTagsAvailable,
                  style: TextStyle(
                    color: textColor.withAlpha(((0.5) * 255).round()),
                  ),
                ),
              ),
            )
          else if (allTags.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      i18n.noTagsYet,
                      style: TextStyle(
                        color: textColor.withAlpha(((0.5) * 255).round()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: 跳转到标签管理页面
                      },
                      child: Text(i18n.createTag),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTags.map((tag) {
                    return _buildTagChip(
                      tag,
                      isSelected: false,
                      colorScheme: colorScheme,
                      textColor: textColor,
                      onTap: () => _addTag(tag.id),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建标签 Chip
  Widget _buildTagChip(
    TaskTagEntity tag, {
    required bool isSelected,
    required ColorScheme colorScheme,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    final tagColor = TagColorUtils.fromHex(tag.color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? tagColor.withAlpha(((0.2) * 255).round())
              : tagColor.withAlpha(((0.1) * 255).round()),
          border: Border.all(
            color: isSelected
                ? tagColor
                : tagColor.withAlpha(((0.5) * 255).round()),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tagColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tag.name,
              style: TextStyle(
                color: isSelected ? tagColor : textColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 14,
                color: tagColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建类型筛选 Chip
  Widget _buildTypeFilterChip(
    TagType? type,
    String label,
    ColorScheme colorScheme,
    Color textColor,
  ) {
    return Selector<TagProvider, TagType?>(
      selector: (_, provider) => provider.filterType,
      builder: (context, filterType, child) {
        final isSelected = filterType == type;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              context.read<TagProvider>().setFilterType(selected ? type : null);
            },
            backgroundColor:
                colorScheme.surface.withAlpha(((0.5) * 255).round()),
            selectedColor: colorScheme.primary.withAlpha(((0.2) * 255).round()),
            labelStyle: TextStyle(
              color: isSelected ? colorScheme.primary : textColor,
            ),
          ),
        );
      },
    );
  }

  /// 添加标签
  void _addTag(String tagId) {
    final newTags = [...widget.selectedTagIds, tagId];
    widget.onTagsChanged(newTags);
  }

  /// 移除标签
  void _removeTag(String tagId) {
    final newTags = widget.selectedTagIds.where((id) => id != tagId).toList();
    widget.onTagsChanged(newTags);
  }
}
