import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowTitleBar extends StatelessWidget {
  final bool isDark;

  const WindowTitleBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.transparent, // 设置为全透明
              child: MoveWindow(),
            ),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WindowButtonColors(
      iconNormal: Theme.of(context).colorScheme.onSurface,
      mouseOver: Theme.of(context).colorScheme.primary.withAlpha(17), // 使用透明度
      mouseDown: Theme.of(context).colorScheme.primary.withAlpha(34), // 使用透明度
      iconMouseOver: Theme.of(context).colorScheme.primary,
      iconMouseDown: Theme.of(context).colorScheme.primary,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Theme.of(context).colorScheme.onSurface,
      iconMouseOver: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: colors),
        MaximizeWindowButton(colors: colors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
