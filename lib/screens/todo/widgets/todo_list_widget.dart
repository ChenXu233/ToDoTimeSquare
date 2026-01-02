import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../i18n/i18n.dart';
import '../../../providers/todo_provider.dart';
import '../../../models/models.dart';
import 'modal/add_todo/add_todo_modal.dart';
import 'todo_item.dart';
import 'todo_drag_target.dart';
import '../../../widgets/glass/glass_popup_menu.dart';

class TodoListWidget extends StatefulWidget {
  final bool isCompact;
  const TodoListWidget({super.key, this.isCompact = false});

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  void _showAddTodoModal(BuildContext context, {TaskModel? todo}) {
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

  /// 显示操作菜单（长按/右键）
  void _showContextMenu(BuildContext context, TaskModel todo, Offset position) {
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
              const SizedBox(width: 8),
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

  /// 构建主任务项（带拖拽）
  Widget _buildTodoItem(
    BuildContext context,
    TaskModel todo,
    TodoProvider provider,
  ) {
    return Padding(
      key: Key(todo.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: TodoDragTarget(
        todo: todo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主任务（可拖拽）- 拖拽仅由项内的手柄触发
            TodoItem(
              todo: todo,
              enableReorder: true,
              onToggle: () => provider.toggleTodo(todo.id),
              onShowMenu: (position) =>
                  _showContextMenu(context, todo, position),
              onEdit: () => _showAddTodoModal(context, todo: todo),
              onDelete: () => provider.removeTodo(todo.id),
            ),
            // 子任务（不可拖拽，但可操作）
            Consumer<TodoProvider>(
              builder: (context, subProvider, child) {
                final subTasks = subProvider.getSubTasks(todo.id);
                if (subTasks.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 8),
                  child: Column(
                    children: subTasks.map((subTask) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TodoDragTarget(
                          todo: subTask,
                          child: TodoItem(
                            todo: subTask,
                            enableReorder: true,
                            onToggle: () => subProvider.toggleTodo(subTask.id),
                            onShowMenu: (position) =>
                                _showContextMenu(context, subTask, position),
                            onEdit: () =>
                                _showAddTodoModal(context, todo: subTask),
                            onDelete: () => subProvider.removeTodo(subTask.id),
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
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final todos = todoProvider.todos.where((t) => t.parentId == null).toList();

    return Stack(
      children: [
        // List Area
        todos.isEmpty
            ? Center(
                child: Text(
                  APPi18n.of(context)!.noTasksYet,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: todos.length + 1,
                itemBuilder: (context, index) {
                  if (index == todos.length) {
                    return DragTarget<TaskModel>(
                      onWillAcceptWithDetails: (details) {
                        return true;
                      },
                      onAcceptWithDetails: (details) {
                        final data = details.data;
                        if (data.parentId != null) {
                          todoProvider.detachFromParent(data.id);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (candidateData.isNotEmpty) {
                          final data = candidateData.first;
                          if (data != null && data.parentId != null) {
                            return Container(
                              height: 80,
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.blue.withValues(alpha: 0.1),
                              ),
                              child: const Center(
                                child: Text(
                                  "松手转为主任务",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox(height: 100);
                      },
                    );
                  }
                  final todo = todos[index];
                  return _buildTodoItem(
                    context,
                    todo,
                    todoProvider,
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
