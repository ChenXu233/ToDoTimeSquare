import 'package:flutter/material.dart';
import '../../../i18n/i18n.dart';

/// 空状态组件
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final double size;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: size,
              color: Theme.of(context).hintColor.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(128),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 习惯空状态组件
class HabitEmptyState extends StatelessWidget {
  final APPi18n i18n;

  const HabitEmptyState({
    super.key,
    required this.i18n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.loop_outlined,
              size: 64,
              color: Theme.of(context).hintColor.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              i18n.noHabitsYet,
              style: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(128),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              i18n.createFirstHabit,
              style: TextStyle(
                color: Theme.of(context).hintColor.withAlpha(80),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
