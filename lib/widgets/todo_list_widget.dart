import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'add_todo_modal.dart';
import 'todo_item.dart';
import 'glass_popup_menu.dart';

class TodoListWidget extends StatelessWidget {
  final bool isCompact;
  const TodoListWidget({super.key, this.isCompact = false});

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
    showGlassMenu(
      context: context,
      position: position - const Offset(-10, 20),
      items: [
        GlassPopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Edit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const GlassPopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'edit') {
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
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                itemCount: todoProvider.todos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final todo = todoProvider.todos[index];
                  return TodoItem(
                    todo: todo,
                    onToggle: () => todoProvider.toggleTodo(todo.id),
                    onDelete: () => todoProvider.removeTodo(todo.id),
                    onShowMenu: (position) =>
                        _showEditDeleteMenu(context, todo, position),
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
