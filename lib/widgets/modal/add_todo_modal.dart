import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../../i18n/i18n.dart';
import '../glass/glass_container.dart';

class AddTodoModal extends StatefulWidget {
  final Todo? todo;
  const AddTodoModal({super.key, this.todo});

  @override
  State<AddTodoModal> createState() => _AddTodoModalState();
}

class _AddTodoModalState extends State<AddTodoModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TodoImportance _importance = TodoImportance.medium;
  Duration? _estimatedDuration;
  DateTime? _plannedStartTime;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
      _importance = widget.todo!.importance;
      _estimatedDuration = widget.todo!.estimatedDuration;
      _plannedStartTime = widget.todo!.plannedStartTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDuration() async {
    // Simple duration picker using dialog
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 30),
      helpText: "Select Duration (Hours : Minutes)",
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _estimatedDuration = Duration(hours: time.hour, minutes: time.minute);
      });
    }
  }

  Future<void> _pickStartTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _plannedStartTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.todo != null) {
        final updatedTodo = Todo(
          id: widget.todo!.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          estimatedDuration: _estimatedDuration,
          importance: _importance,
          plannedStartTime: _plannedStartTime,
          isCompleted: widget.todo!.isCompleted,
        );
        Provider.of<TodoProvider>(
          context,
          listen: false,
        ).updateTodo(updatedTodo);
      } else {
        Provider.of<TodoProvider>(context, listen: false).addTodo(
          _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          estimatedDuration: _estimatedDuration,
          importance: _importance,
          plannedStartTime: _plannedStartTime,
        );
      }
      Navigator.pop(context);
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
            padding: const EdgeInsets.all(24),
            color: glassColor,
            opacity: 0.1, // Increased opacity for better visibility
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.todo != null ? "Edit Todo" : i18n.addTask,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

                  // Importance
                  Text(
                    i18n.importance,
                    style: TextStyle(
                      color: textColor.withAlpha(((0.7) * 255).round()),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TodoImportance>(
                    segments: [
                      ButtonSegment(
                        value: TodoImportance.low,
                        label: Text(i18n.low),
                      ),
                      ButtonSegment(
                        value: TodoImportance.medium,
                        label: Text(i18n.medium),
                      ),
                      ButtonSegment(
                        value: TodoImportance.high,
                        label: Text(i18n.high),
                      ),
                    ],
                    selected: {_importance},
                    onSelectionChanged: (Set<TodoImportance> newSelection) {
                      setState(() {
                        _importance = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return colorScheme.onSecondaryContainer;
                        }
                        return textColor;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Duration & Start Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDuration,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: textColor.withAlpha(
                                  ((0.3) * 255).round(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i18n.duration,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withAlpha(
                                      ((0.7) * 255).round(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _estimatedDuration != null
                                      ? "${_estimatedDuration!.inHours}h ${_estimatedDuration!.inMinutes % 60}m"
                                      : i18n.notSet,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: textColor.withAlpha(
                                  ((0.3) * 255).round(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i18n.startTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withAlpha(
                                      ((0.7) * 255).round(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _plannedStartTime != null
                                      ? "${_plannedStartTime!.month}/${_plannedStartTime!.day} ${_plannedStartTime!.hour}:${_plannedStartTime!.minute.toString().padLeft(2, '0')}"
                                      : i18n.notSet,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
