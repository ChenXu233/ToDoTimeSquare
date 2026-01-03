import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/todo_provider.dart';
import '../../../../../i18n/i18n.dart';
import '../../../../../widgets/glass/glass_container.dart';
import '../../../../../models/models.dart';
import 'component/importance_segmented_button.dart';
import 'component/parent_task_dropdown.dart';
import 'component/duration_picker.dart';
import 'component/start_time_picker.dart';
import 'component/tag_selector.dart';

class AddTodoModal extends StatefulWidget {
  final TaskModel? todo;
  const AddTodoModal({super.key, this.todo});

  @override
  State<AddTodoModal> createState() => _AddTodoModalState();
}

class _AddTodoModalState extends State<AddTodoModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TodoImportance _importance = TodoImportance.medium;
  int? _estimatedDuration; // minutes
  DateTime? _plannedStartTime;
  String? _parentId;
  List<String> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
      _importance =
          TodoImportance.values[(widget.todo!.importance - 1).clamp(0, 2)];
      _estimatedDuration = widget.todo!.estimatedDuration;
      _plannedStartTime = widget.todo!.plannedStartTime;
      _parentId = widget.todo!.parentId;
      _loadExistingTags();
    }
  }

  Future<void> _loadExistingTags() async {
    if (widget.todo == null) return;
    final tags =
        await context.read<TodoProvider>().getTagsForTask(widget.todo!.id);
    if (mounted) {
      setState(() {
        _selectedTagIds = tags.map((t) => t.id).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDurationChanged(Duration? duration) {
    if (!mounted) return;
    setState(() {
      // Convert Duration to minutes for storage
      _estimatedDuration = duration != null
          ? duration.inHours * 60 + duration.inMinutes
          : null;
    });
  }

  void _onStartTimeChanged(DateTime? startTime) {
    if (!mounted) return;
    setState(() {
      _plannedStartTime = startTime;
    });
  }

  void _onParentChanged(String? parentId) {
    if (!mounted) return;
    setState(() {
      _parentId = parentId;
    });
  }

  void _onTagsChanged(List<String> tagIds) {
    if (!mounted) return;
    setState(() {
      _selectedTagIds = tagIds;
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<TodoProvider>(context, listen: false);

      if (widget.todo != null) {
        final updatedTodo = widget.todo!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          estimatedDuration: _estimatedDuration,
          importance: _importance.index + 1,
          plannedStartTime: _plannedStartTime,
          parentId: _parentId,
        );
        await provider.updateTodo(updatedTodo);
        // 更新标签
        await provider.setTagsForTask(widget.todo!.id, _selectedTagIds);
      } else {
        final newTodoId = provider.addTodo(
          _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          estimatedDuration: _estimatedDuration,
          importance: _importance,
          plannedStartTime: _plannedStartTime,
          parentId: _parentId,
        );
        // 添加标签
        if (_selectedTagIds.isNotEmpty) {
          await provider.setTagsForTask(newTodoId, _selectedTagIds);
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    // Use a surface color with a slight tint of primary for better visibility and aesthetics
    final glassColor = Color.alphaBlend(
      colorScheme.primary.withAlpha(((0.08) * 255).round()),
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Material(
          color: Colors.transparent,
          child: GlassContainer(
            margin: const EdgeInsets.all(24),
            padding: EdgeInsets.zero, // 移除内边距，由内部 Scroll 接管
            color: glassColor,
            opacity: 0.1,
            blur: 20,
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(
                ((0.3) * 255).round(),
              ),
              width: 1,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏（固定不滚动）
                  _buildHeader(context, i18n, textColor),
                  const SizedBox(height: 16),

                  // 表单内容（可滚动）
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildFormContent(
                        context,
                        i18n,
                        colorScheme,
                        textColor,
                      ),
                    ),
                  ),

                  // 底部按钮栏（固定不滚动）
                  _buildFooter(context, i18n, textColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, APPi18n i18n, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.todo != null ? "Edit Todo" : i18n.addTask,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: textColor.withAlpha(((0.5) * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(
    BuildContext context,
    APPi18n i18n,
    ColorScheme colorScheme,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        TextFormField(
          controller: _titleController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: i18n.taskName,
            labelStyle: TextStyle(
              color: textColor.withAlpha(((0.7) * 255).round()),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: textColor.withAlpha(((0.3) * 255).round()),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withAlpha(
              ((0.3) * 255).round(),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return i18n.pleaseEnterTitle;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: i18n.taskDescription,
            labelStyle: TextStyle(
              color: textColor.withAlpha(((0.7) * 255).round()),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: textColor.withAlpha(((0.3) * 255).round()),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withAlpha(
              ((0.3) * 255).round(),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Importance
        ImportanceSegmentedButton(
          importance: _importance,
          onChanged: (newImportance) {
            if (!mounted) return;
            setState(() {
              _importance = newImportance;
            });
          },
        ),
        const SizedBox(height: 16),

        // Duration & Start Time
        Row(
          children: [
            Expanded(
              child: DurationPicker(
                duration: _estimatedDuration != null
                    ? Duration(minutes: _estimatedDuration!)
                    : null,
                onPick: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 0, minute: 30),
                    helpText: "Select Duration (Hours : Minutes)",
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (!mounted) return;
                  if (time != null) {
                    _onDurationChanged(
                      Duration(
                        hours: time.hour,
                        minutes: time.minute,
                      ),
                    );
                  }
                },
                label: i18n.duration,
                notSetText: i18n.notSet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StartTimePicker(
                startTime: _plannedStartTime,
                onPick: () async {
                  final DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365),
                    ),
                  );
                  if (!context.mounted) return;
                  if (date != null) {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (!context.mounted) return;
                    if (time != null) {
                      _onStartTimeChanged(
                        DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  }
                },
                label: i18n.startTime,
                notSetText: i18n.notSet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Parent Task
        Text(
          i18n.parentTask,
          style: TextStyle(
            color: textColor.withAlpha(((0.7) * 255).round()),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ParentTaskDropdown(
          parentId: _parentId,
          onChanged: _onParentChanged,
          currentTodoId: widget.todo?.id,
        ),
        const SizedBox(height: 16),

        // Tags
        TagSelector(
          selectedTagIds: _selectedTagIds,
          onTagsChanged: _onTagsChanged,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, APPi18n i18n, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: textColor.withAlpha(((0.1) * 255).round()),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.cancel),
          ),
          const SizedBox(width: 16),
          FilledButton(onPressed: _submit, child: Text(i18n.save)),
        ],
      ),
    );
  }
}
