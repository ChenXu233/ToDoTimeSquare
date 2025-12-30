import 'package:flutter/material.dart';

class ConsistentIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const ConsistentIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color ?? theme.colorScheme.primary,
        size: size,
      ),
    );
  }
}