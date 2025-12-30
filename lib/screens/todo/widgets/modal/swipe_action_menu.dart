import 'package:flutter/material.dart';
import '../../../../i18n/i18n.dart';
import '../../../../models/todo.dart';

/// 左滑操作菜单结果
enum SwipeActionResult {
  edit,
  delete,
  cancel,
}

/// 左滑操作按钮
class SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const SwipeActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: double.infinity,
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左滑操作菜单（显示在列表项右侧）
class SwipeActionMenu extends StatelessWidget {
  final Todo todo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SwipeActionMenu({
    super.key,
    required this.todo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 取消按钮（灰色）
        SwipeActionButton(
          icon: Icons.close,
          label: i18n.cancel,
          color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
          onTap: onEdit, // 取消就是不做任何操作
        ),
        const SizedBox(width: 1),
        // 删除按钮（红色）
        SwipeActionButton(
          icon: Icons.delete,
          label: i18n.delete,
          color: Colors.red,
          onTap: onDelete,
        ),
        const SizedBox(width: 1),
        // 编辑按钮（主色）
        SwipeActionButton(
          icon: Icons.edit,
          label: i18n.edit,
          color: Theme.of(context).colorScheme.primary,
          onTap: onEdit,
        ),
      ],
    );
  }
}
