import 'package:flutter/material.dart';
import '../../../../i18n/i18n.dart';
import '../../../models/models.dart';
import '../../../widgets/glass/glass_container.dart';
import 'todo_draggable.dart';

class TodoItem extends StatefulWidget {
  final TaskModel todo;
  final VoidCallback onToggle;
  final Function(Offset) onShowMenu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool enableReorder;
  final int? reorderIndex;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onShowMenu,
    required this.onEdit,
    required this.onDelete,
    this.enableReorder = false,
    this.reorderIndex,
  });

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<double>? _currentAnimation;
  VoidCallback? _currentAnimationListener;
  void Function(AnimationStatus)? _currentStatusListener;

  double _dragExtent = 0;
  bool _isSwipedOut = false;

  // 滑动卡住的阈值（屏幕宽度的30%）
  double get _dismissThreshold => MediaQuery.of(context).size.width * 0.20;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getImportanceColor(int importance) {
    switch (importance) {
      case 3: // high
        return Colors.redAccent;
      case 2: // medium
        return Colors.orangeAccent;
      case 1: // low
        return Colors.greenAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // Stop any running animation so user drag is immediately reflected
    if (_animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }

    // If already swiped out, only allow rightward drag to restore
    if (_isSwipedOut) {
      if (details.delta.dx > 0) {
        setState(() {
          _dragExtent += details.delta.dx;
          // Clamp so it won't overshoot to the right
          if (_dragExtent >= 0) {
            // User dragged fully back to origin; clear swiped-out state so release will behave normally
            _dragExtent = 0;
            _isSwipedOut = false;
          } else {
          }
        });
      }
      return;
    }

    // If currently have left offset, allow rightward drag to cancel
    if (_dragExtent < 0 && details.delta.dx > 0) {
      setState(() {
        _dragExtent += details.delta.dx;
        if (_dragExtent > 0) _dragExtent = 0;
      });
      return;
    }

    // Start left swipe
    if (details.delta.dx < 0) {
      setState(() {
        _dragExtent += details.delta.dx;
        // Allow a small overscroll but clamp to a reasonable max
        final maxOverscroll = -_dismissThreshold * 1.05;
        if (_dragExtent < maxOverscroll) _dragExtent = maxOverscroll;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    // If currently in swiped-out state, handle release appropriately
    if (_isSwipedOut) {
      if (_dragExtent >= 0) {
        // user dragged back to origin — restore
        _animateTo(0);
      } else {
        // not fully restored — animate back to swiped position
        _animateTo(-_dismissThreshold);
      }
      return;
    }


    // 如果滑动超过阈值，卡住
    if (_dragExtent <= -_dismissThreshold) {
      _animateTo(-_dismissThreshold);
    } else {
      // 否则恢复原位
      _animateTo(0);
    }
  }

  void _resetPosition() {
    _animateTo(0);
  }

  void _handleButtonTap(VoidCallback action) {
    action();
    _resetPosition();
  }

  void _animateTo(double target) {
    // Cancel any existing animation and its listeners
    if (_currentAnimation != null && _currentAnimationListener != null) {
      _currentAnimation!.removeListener(_currentAnimationListener!);
      _currentAnimation = null;
    }
    if (_currentStatusListener != null) {
      _animationController.removeStatusListener(_currentStatusListener!);
      _currentStatusListener = null;
    }

    _animationController.stop();
    _animationController.reset();

    final double start = _dragExtent;
    _currentAnimation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _currentAnimationListener = () {
      if (!mounted) return;
      setState(() {
        _dragExtent = _currentAnimation!.value;
      });
    };

    _currentAnimation!.addListener(_currentAnimationListener!);

    _currentStatusListener = (AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        // Cleanup listeners
        if (_currentAnimation != null && _currentAnimationListener != null) {
          _currentAnimation!.removeListener(_currentAnimationListener!);
        }
        if (_currentStatusListener != null) {
          _animationController.removeStatusListener(_currentStatusListener!);
        }
        _currentAnimation = null;
        _currentAnimationListener = null;
        _currentStatusListener = null;

        if (!mounted) return;
        setState(() {
          _dragExtent = target;
          _isSwipedOut = (target == -_dismissThreshold);
        });
        _animationController.reset();
      }
    };

    _animationController.addStatusListener(_currentStatusListener!);
    _animationController.forward();
  }

  // 获取当前滑动偏移量（用于动画）

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final i18n = APPi18n.of(context)!;

    // 背景操作按钮
    Widget background = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 取消按钮（灰色）
            _buildSwipeButton(
              icon: Icons.close,
              label: i18n.cancel,
              color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
              onTap: () => _handleButtonTap(() {}),
            ),
            const SizedBox(width: 1),
            // 删除按钮（红色）
            _buildSwipeButton(
              icon: Icons.delete,
              label: i18n.delete,
              color: Colors.red,
              onTap: () => _handleButtonTap(widget.onDelete),
            ),
            const SizedBox(width: 1),
            // 编辑按钮（主色）
            _buildSwipeButton(
              icon: Icons.edit,
              label: i18n.edit,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => _handleButtonTap(widget.onEdit),
            ),
          ],
        ),
      ),
    );

    // 任务内容构建方法
    Widget buildContent({bool isFeedback = false}) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? Colors.black : Colors.white,
        opacity: isFeedback
            ? 0.6
            : 0.05, // Feedback slightly less opaque to show background blur
        border: isFeedback
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        child: Row(
          children: [
            // 拖拽手柄（启用拖拽时显示）
            if (widget.enableReorder)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: isFeedback
                    ? const TodoDragHandle()
                    : TodoDraggable(
                        todo: widget.todo,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Transform.scale(
                            scale: 1.02,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: buildContent(isFeedback: true),
                            ),
                          ),
                        ),
                        child: const TodoDragHandle(),
                      ),
              ),
            Checkbox(
              value: widget.todo.isCompleted,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) => widget.onToggle(),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.todo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: widget.todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: widget.todo.isCompleted
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.todo.description ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (widget.todo.plannedStartTime != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${widget.todo.plannedStartTime!.month}/${widget.todo.plannedStartTime!.day} ${widget.todo.plannedStartTime!.hour}:${widget.todo.plannedStartTime!.minute.toString().padLeft(2, '0')}",
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
                        if (widget.todo.estimatedDuration != null)
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.todo.estimatedDuration! ~/ 60}h ${widget.todo.estimatedDuration! % 60}m",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface
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
                color: _getImportanceColor(widget.todo.importance),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }

    final content = buildContent();

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 背景操作栏（铺满内容高度）
          Positioned.fill(child: background),
          // 滑动的内容（使用 Transform.translate 实现滑动），偏移由 _dragExtent 驱动
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onHorizontalDragUpdate: _handleDragUpdate,
                  onHorizontalDragEnd: _handleDragEnd,
                  onLongPressStart: (details) {
                    widget.onShowMenu(details.globalPosition);
                  },
                  onSecondaryTapDown: (details) {
                    widget.onShowMenu(details.globalPosition);
                  },
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minWidth: 70),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
