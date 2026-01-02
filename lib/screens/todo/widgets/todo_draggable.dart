import 'package:flutter/material.dart';
import '../../../models/models.dart';

class TodoDraggable extends StatelessWidget {
  final TaskModel todo;
  final Widget child;
  final Widget feedback;

  const TodoDraggable({
    super.key,
    required this.todo,
    required this.child,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<TaskModel>(
      data: todo,
      feedback: feedback,
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      child: child,
    );
  }
}

class TodoDragHandle extends StatelessWidget {
  const TodoDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.drag_indicator,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
    );
  }
}
