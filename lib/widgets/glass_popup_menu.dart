import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassPopupMenuItem<T> extends StatelessWidget {
  final T value;
  final Widget child;
  final VoidCallback? onTap;

  const GlassPopupMenuItem({
    super.key,
    required this.value,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
        Navigator.of(context).pop(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      ),
    );
  }
}

Future<T?> showGlassMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<GlassPopupMenuItem<T>> items,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
              Positioned(
                left: position.dx,
                top: position.dy,
                child: Material(
                  color: Colors.transparent,
                  child: GlassContainer(
                    blur: 20,
                    opacity: 0.1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
