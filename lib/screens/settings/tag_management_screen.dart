import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../i18n/i18n.dart';
import '../../models/database/schema/task_tags.dart';
import '../../models/entities/task_tag_model.dart';
import '../../providers/tag_provider.dart';
import '../../widgets/glass/glass_container.dart';

/// 标签管理页面
class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final _searchController = TextEditingController();
  TagType? _filterType;

  @override
  void initState() {
    super.initState();
    context.read<TagProvider>().loadTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.tagManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTagDialog(context),
            tooltip: i18n.createTag,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: i18n.searchTags,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                context.read<TagProvider>().setSearchQuery(value);
              },
            ),
          ),

          // 类型筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

          const SizedBox(height: 16),

          // 标签列表
          Expanded(
            child: Consumer<TagProvider>(
              builder: (context, tagProvider, child) {
                if (tagProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tags = tagProvider.filteredTags;

                if (tags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: textColor.withAlpha(((0.3) * 255).round()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          i18n.noTagsYet,
                          style: TextStyle(
                            color: textColor.withAlpha(((0.5) * 255).round()),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showTagDialog(context),
                          icon: const Icon(Icons.add),
                          label: Text(i18n.createTag),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return _buildTagItem(context, tag, colorScheme, textColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(
    TagType? type,
    String label,
    ColorScheme colorScheme,
    Color textColor,
  ) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterType = selected ? type : null;
          });
          context.read<TagProvider>().setFilterType(selected ? type : null);
        },
      ),
    );
  }

  Widget _buildTagItem(
    BuildContext context,
    TaskTagEntity tag,
    ColorScheme colorScheme,
    Color textColor,
  ) {
    final i18n = APPi18n.of(context)!;
    final tagColor = TagColorUtils.fromHex(tag.color);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest.withAlpha(150),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // 颜色指示器
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // 标签信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        TaskTagEntity.typeNames[tag.type] ?? tag.type.name,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tag.usageCount} ${i18n.usageCount}',
                      style: TextStyle(
                        color: textColor.withAlpha(((0.5) * 255).round()),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 操作按钮
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: textColor.withAlpha(((0.7) * 255).round()),
                ),
                onPressed: () => _showTagDialog(context, tag: tag),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: textColor.withAlpha(((0.7) * 255).round()),
                ),
                onPressed: () => _confirmDelete(context, tag),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTagDialog(BuildContext context, {TaskTagEntity? tag}) {
    final i18n = APPi18n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    final nameController = TextEditingController(text: tag?.name ?? '');
    TagType selectedType = tag?.type ?? TagType.custom;
    String selectedColor = tag?.color ?? TagColorUtils.getRandomColor();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tag != null ? i18n.editTag : i18n.createTag),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 名称输入
              TextField(
                controller: nameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: i18n.tagName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 类型选择
              Text(
                i18n.tagType,
                style: TextStyle(
                  color: textColor.withAlpha(((0.7) * 255).round()),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TagType.values.map((type) {
                  return ChoiceChip(
                    label: Text(TaskTagEntity.typeNames[type] ?? type.name),
                    selected: selectedType == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedType = type;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 颜色选择
              Text(
                i18n.tagColor,
                style: TextStyle(
                  color: textColor.withAlpha(((0.7) * 255).round()),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TagColorUtils.presetColors.map((color) {
                  final isSelected = color == selectedColor;
                  final colorValue = TagColorUtils.fromHex(color);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: colorValue.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(i18n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final tagProvider = context.read<TagProvider>();

                if (tag != null) {
                  // 更新
                  await tagProvider.updateTag(
                    tag.copyWith(
                      name: nameController.text,
                      type: selectedType,
                      color: selectedColor,
                    ),
                  );
                } else {
                  // 创建
                  await tagProvider.createTag(
                    name: nameController.text,
                    type: selectedType,
                    color: selectedColor,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(i18n.save),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, TaskTagEntity tag) {
    final i18n = APPi18n.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(i18n.deleteTag),
          content: Text(i18n.deleteTagConfirm(tag.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(i18n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                await context.read<TagProvider>().deleteTag(tag.id);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(i18n.delete),
            ),
          ],
        );
      },
    );
  }
}
