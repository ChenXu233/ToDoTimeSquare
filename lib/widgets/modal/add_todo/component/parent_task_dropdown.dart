import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/todo_provider.dart';
import '../../../../i18n/i18n.dart';
import '../../../glass/glass_dropdown.dart';

class ParentTaskDropdown extends StatefulWidget {
  final String? parentId;
  final ValueChanged<String?> onChanged;
  final String? currentTodoId;
  final String? searchText;
  const ParentTaskDropdown({
    super.key,
    required this.parentId,
    required this.onChanged,
    this.currentTodoId,
    this.searchText,
  });

  @override
  State<ParentTaskDropdown> createState() => _ParentTaskDropdownState();
}

class _ParentTaskDropdownState extends State<ParentTaskDropdown> {
  late TextEditingController _searchController;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
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
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final effectiveSearchText = widget.searchText ?? _searchText;
        final potentialParents = provider.todos
            .where((t) {
              return t.id != widget.currentTodoId && t.parentId == null;
            })
            .where((t) {
              if (effectiveSearchText.isEmpty) return true;
              return t.title.toLowerCase().contains(
                effectiveSearchText.toLowerCase(),
              );
            })
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索父任务...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassDropdownFormField<String>(
              dropdownPosition: GlassDropdownPosition.below,
              value: widget.parentId,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: textColor.withAlpha(((0.3) * 255).round()),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(
                  ((0.3) * 255).round(),
                ),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(i18n.noparent),
                ),
                ...potentialParents.map((t) {
                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: widget.onChanged,
              dropdownColor: colorScheme.surfaceContainerHighest,
              style: TextStyle(color: textColor),
            ),
          ],
        );
      },
    );
  }
}
