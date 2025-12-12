import 'package:flutter/material.dart';
import '../../../../models/todo.dart';
import '../../../widgets/glass/glass_container.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(Offset) onShowMenu;
  final bool enableDismiss;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onShowMenu,
    this.enableDismiss = true,
  });

  Color _getImportanceColor(TodoImportance importance) {
    switch (importance) {
      case TodoImportance.high:
        return Colors.redAccent;
      case TodoImportance.medium:
        return Colors.orangeAccent;
      case TodoImportance.low:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = GestureDetector(
      onLongPressStart: (details) {
        onShowMenu(details.globalPosition);
      },
      onSecondaryTapDown: (details) {
        onShowMenu(details.globalPosition);
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? Colors.black : Colors.white,
        opacity: 0.05,
        child: Row(
          children: [
            Checkbox(
              value: todo.isCompleted,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) => onToggle(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.isCompleted
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (todo.description != null && todo.description!.isNotEmpty)
                    Text(
                      todo.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  if (todo.plannedStartTime != null ||
                      todo.estimatedDuration != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (todo.plannedStartTime != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${todo.plannedStartTime!.month}/${todo.plannedStartTime!.day} ${todo.plannedStartTime!.hour}:${todo.plannedStartTime!.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (todo.estimatedDuration != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${todo.estimatedDuration!.inHours}h ${todo.estimatedDuration!.inMinutes % 60}m",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getImportanceColor(todo.importance),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enableDismiss) {
      return content;
    }

    return Dismissible(
      key: Key(todo.id),
      onDismissed: (direction) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: content,
    );
  }
}
