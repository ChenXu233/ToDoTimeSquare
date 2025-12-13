import 'package:flutter/material.dart';

class ConsistentIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const ConsistentIcon(
    this.icon, {
    Key? key,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
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