import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../i18n/i18n.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import '../../../providers/todo_provider.dart';
import '../../../models/todo.dart';
import 'modal/add_todo/add_todo_modal.dart';
import 'todo_item.dart';
import '../../../widgets/glass/glass_popup_menu.dart';

class TodoListWidget extends StatefulWidget {
  final bool isCompact;
  const TodoListWidget({super.key, this.isCompact = false});

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  final Set<String> _dismissedTaskIds = {};

  void _showAddTodoModal(BuildContext context, {Todo? todo}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: todo != null ? "Edit Todo" : "Add Todo",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddTodoModal(todo: todo);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  void _showEditDeleteMenu(BuildContext context, Todo todo, Offset position) {
    final i18n = APPi18n.of(context)!;
    showGlassMenu(
      context: context,
      position: position - const Offset(-10, 20),
      items: [
        if (!todo.isCompleted)
          GlassPopupMenuItem(
            value: 'start',
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  i18n.startTask,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        GlassPopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                i18n.edit,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        GlassPopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text(i18n.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'start') {
        context.go('/pomodoro', extra: todo);
      } else if (value == 'edit') {
        _showAddTodoModal(context, todo: todo);
      } else if (value == 'delete') {
        Provider.of<TodoProvider>(context, listen: false).removeTodo(todo.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    return Stack(
      children: [
        // List Area
        todoProvider.todos.isEmpty
            ? Center(
                child: Text(
                  "No tasks yet",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              )
            : ImplicitlyAnimatedList<Todo>(
                padding: const EdgeInsets.only(bottom: 80),
                items: todoProvider.todos
                    .where((t) => t.parentId == null)
                    .toList(),
                areItemsTheSame: (a, b) => a.id == b.id,
                itemBuilder: (context, animation, todo, index) {
                  final isDismissed = _dismissedTaskIds.contains(todo.id);
                  if (isDismissed) {
                    // If dismissed, we return a shrunk box to allow the list to animate the space closing
                    // but we don't render the Dismissible widget again.
                    return SizeFadeTransition(
                      sizeFraction: 0.7,
                      curve: Curves.easeInOut,
                      animation: animation,
                      child: const SizedBox.shrink(),
                    );
                  }

                  return SizeFadeTransition(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
                    animation: animation,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          TodoItem(
                            todo: todo,
                            enableDismiss: true,
                            onToggle: () => todoProvider.toggleTodo(todo.id),
                            onDelete: () {
                              setState(() {
                                _dismissedTaskIds.add(todo.id);
                              });
                              todoProvider.removeTodo(todo.id);
                            },
                            onShowMenu: (position) =>
                                _showEditDeleteMenu(context, todo, position),
                          ),
                          Consumer<TodoProvider>(
                            builder: (context, provider, child) {
                              final subTasks = provider.getSubTasks(todo.id);
                              if (subTasks.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 24.0),
                                child: Column(
                                  children: subTasks.map((subTask) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TodoItem(
                                        todo: subTask,
                                        enableDismiss: true,
                                        onToggle: () =>
                                            provider.toggleTodo(subTask.id),
                                        onDelete: () =>
                                            provider.removeTodo(subTask.id),
                                        onShowMenu: (position) =>
                                            _showEditDeleteMenu(
                                              context,
                                              subTask,
                                              position,
                                            ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
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
