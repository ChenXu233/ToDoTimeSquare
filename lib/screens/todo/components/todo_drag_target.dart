import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/i18n.dart';
import '../../../models/models.dart';
import '../../../providers/todo_provider.dart';

class TodoDragTarget extends StatefulWidget {
  final TaskModel todo;
  final Widget child;

  const TodoDragTarget({
    super.key,
    required this.todo,
    required this.child,
  });

  @override
  State<TodoDragTarget> createState() => _TodoDragTargetState();
}

class _TodoDragTargetState extends State<TodoDragTarget> {
  bool _isHovering = false;
  bool _isTop = false;
  bool _isBottom = false;
  bool _isCenter = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data.id == widget.todo.id) return false;
        // Prevent dragging a parent into its own child/descendant
        // This check should ideally be done in the provider or here if we have access to the tree
        // For now, we'll rely on the provider to handle or reject invalid moves, or simple checks.
        return true;
      },
      onMove: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localOffset = renderBox.globalToLocal(details.offset);
        final height = renderBox.size.height;

        setState(() {
          _isHovering = true;
          // Top 20% -> Reorder above
          // Bottom 20% -> Reorder below
          // Middle 60% -> Convert to subtask
          if (localOffset.dy < height * 0.2) {
            _isTop = true;
            _isBottom = false;
            _isCenter = false;
          } else if (localOffset.dy > height * 0.8) {
            _isTop = false;
            _isBottom = true;
            _isCenter = false;
          } else {
            _isTop = false;
            _isBottom = false;
            _isCenter = true;
          }
        });
      },
      onLeave: (data) {
        setState(() {
          _isHovering = false;
          _isTop = false;
          _isBottom = false;
          _isCenter = false;
        });
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final provider = Provider.of<TodoProvider>(context, listen: false);
        
        if (_isCenter) {
          provider.convertToSubtask(data.id, widget.todo.id);
        } else if (_isTop) {
          provider.moveTodoTo(data.id, widget.todo.id, above: true);
        } else if (_isBottom) {
          provider.moveTodoTo(data.id, widget.todo.id, above: false);
        }

        setState(() {
          _isHovering = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        if (_isHovering) {
          if (_isCenter) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.child,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        APPi18n.of(context)?.dropToSubtask ?? 'Release to convert to subtask',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.white,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (_isTop) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                widget.child,
              ],
            );
          } else if (_isBottom) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.child,
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            );
          }
        }
        return widget.child;
      },
    );
  }
}
