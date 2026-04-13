import 'package:flutter/material.dart';
import '../../../i18n/i18n.dart';
import '../../../widgets/glass/glass_container.dart';

Future<void> showPomodoroInfoDialog(BuildContext context) {
  final i18n = APPi18n.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        color: isDark ? Colors.black : Colors.white,
        opacity: 0.1,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.pomodoroInfo,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              i18n.pomodoroInfoContent,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(i18n.cancel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
