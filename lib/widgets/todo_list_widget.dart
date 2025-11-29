import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'glass_container.dart';
import 'add_todo_modal.dart';

class TodoListWidget extends StatelessWidget {
  final bool isCompact;
  const TodoListWidget({super.key, this.isCompact = false});

  void _showAddTodoModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Todo",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const AddTodoModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

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
    final todoProvider = Provider.of<TodoProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // List Area
        todoProvider.todos.isEmpty
                  ? Center(
                child: Text(
                  "No tasks yet",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(((0.4)*255).round()),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                itemCount: todoProvider.todos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final todo = todoProvider.todos[index];
                  return Dismissible(
                    key: Key(todo.id),
                    onDismissed: (direction) {
                      todoProvider.removeTodo(todo.id);
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(((0.8)*255).round()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isDark ? Colors.black : Colors.white,
                      opacity: 0.05,
                      child: Row(
                        children: [
                          Checkbox(
                            value: todo.isCompleted,
                            activeColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (value) {
                              todoProvider.toggleTodo(todo.id);
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todo.title,
                                    style: TextStyle(
                                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                      color: todo.isCompleted
                                          ? Theme.of(context).colorScheme.onSurface.withAlpha(((0.5)*255).round())
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
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(((0.6)*255).round()),
                                    ),
                                  ),
                                if (todo.plannedStartTime != null || todo.estimatedDuration != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        if (todo.plannedStartTime != null)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(((0.5)*255).round())),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${todo.plannedStartTime!.month}/${todo.plannedStartTime!.day} ${todo.plannedStartTime!.hour}:${todo.plannedStartTime!.minute.toString().padLeft(2, '0')}",
                                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withAlpha(((0.5)*255).round())),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (todo.estimatedDuration != null)
                                          Row(
                                            children: [
                                              Icon(Icons.timer, size: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(((0.5)*255).round())),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${todo.estimatedDuration!.inHours}h ${todo.estimatedDuration!.inMinutes % 60}m",
                                                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withAlpha(((0.5)*255).round())),
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
                },
              ),
        
        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddTodoModal(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}


