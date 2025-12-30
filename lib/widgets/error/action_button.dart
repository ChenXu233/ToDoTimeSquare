import 'package:flutter/material.dart';

/// 操作按钮组件 - 用于错误恢复操作的按钮
class ActionButton extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标签文字
  final String label;

  /// 点击回调
  final VoidCallback onPressed;

  /// 是否为主要按钮（高亮样式）
  final bool isPrimary;

  /// 是否使用深色主题
  final bool isDark;

  /// 按钮宽度
  final double? width;

  /// 自定义背景色
  final Color? backgroundColor;

  /// 自定义文字颜色
  final Color? textColor;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDark = true,
    this.width,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? _getBackgroundColor();
    final fgColor = textColor ?? _getTextColor();

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(
                    color: (isDark ? Colors.white30 : Colors.black26),
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: fgColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 14,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return child;
  }

  Color _getBackgroundColor() {
    if (isPrimary) {
      return isDark ? Colors.white : Colors.black87;
    }
    return Colors.transparent;
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    if (isPrimary) {
      return isDark ? Colors.black : Colors.white;
    }
    return isDark ? Colors.white70 : Colors.black87;
  }
}

/// 关闭按钮
class DismissButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;

  const DismissButton({
    super.key,
    required this.onPressed,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Icons.close,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    );
  }
}

/// 图标按钮
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDark;
  final Color? iconColor;
  final double size;

  const IconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isDark = true,
    this.iconColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: size,
            color: iconColor ?? (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
