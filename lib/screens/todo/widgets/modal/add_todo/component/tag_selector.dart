import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ToDoTimeSquare/providers/tag_provider.dart';
import 'package:ToDoTimeSquare/models/entities/task_tag_model.dart';
import 'package:ToDoTimeSquare/models/database/schema/task_tags.dart';
import 'package:ToDoTimeSquare/i18n/i18n.dart';

/// 标签选择器组件
class TagSelector extends StatefulWidget {
  /// 当前选中的标签 ID 列表
  final List<String> selectedTagIds;

  /// 标签变化回调
  final ValueChanged<List<String>> onTagsChanged;

  /// 最大显示标签数量
  final int maxVisibleTags;

  const TagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.maxVisibleTags = 3,
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
        final filteredTags = tagProvider.filteredTags;

        // 获取选中的标签对象
        final selectedTags = allTags
            .where((tag) => widget.selectedTagIds.contains(tag.id))
            .toList();

        // 获取未选中的标签
        final availableTags = allTags
            .where((tag) => !widget.selectedTagIds.contains(tag.id))
            .toList();

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
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                if (_isExpanded) {
                  _focusNode.requestFocus();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isExpanded
                        ? colorScheme.primary
                        : textColor.withAlpha(((0.3) * 255).round()),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: textColor.withAlpha(((0.7) * 255).round()),
                    ),
                  ],
                ),
              ),
            ),

            // 展开的标签选择面板
            if (_isExpanded) _buildExpandedPanel(
              context,
              allTags,
              filteredTags,
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

  Widget _buildExpandedPanel(
    BuildContext context,
    List<TaskTagEntity> allTags,
    List<TaskTagEntity> filteredTags,
    List<TaskTagEntity> availableTags,
    ColorScheme colorScheme,
    Color textColor,
    APPi18n i18n,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withAlpha(((0.3) * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // 标签类型筛选
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

          // 标签列表
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
            SizedBox(
              height: 200,
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
            color: isSelected ? tagColor : tagColor.withAlpha(((0.5) * 255).round()),
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

  Widget _buildTypeFilterChip(
    TagType? type,
    String label,
    ColorScheme colorScheme,
    Color textColor,
  ) {
    final isSelected = context.watch<TagProvider>().filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          context.read<TagProvider>().setFilterType(selected ? type : null);
        },
        backgroundColor: colorScheme.surface.withAlpha(((0.5) * 255).round()),
        selectedColor: colorScheme.primary.withAlpha(((0.2) * 255).round()),
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.primary : textColor,
        ),
      ),
    );
  }

  void _addTag(String tagId) {
    final newTags = [...widget.selectedTagIds, tagId];
    widget.onTagsChanged(newTags);
  }

  void _removeTag(String tagId) {
    final newTags = widget.selectedTagIds.where((id) => id != tagId).toList();
    widget.onTagsChanged(newTags);
  }
}
