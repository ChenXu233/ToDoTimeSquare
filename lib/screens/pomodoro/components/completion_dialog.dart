import 'package:flutter/material.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';

Future<void> showPomodoroCompletionDialog(BuildContext context) {
  final i18n = APPi18n.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          color: isDark ? Colors.black : Colors.white,
          opacity: 0.1,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Text(
                    i18n.taskCompletedDialogTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                i18n.taskCompletedDialogMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(i18n.taskCompletedDialogButton),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
