import 'package:flutter/material.dart';

class DurationPicker extends StatelessWidget {
  final Duration? duration;
  final VoidCallback onPick;
  final String label;
  final String notSetText;
  const DurationPicker({
    super.key,
    required this.duration,
    required this.onPick,
    required this.label,
    required this.notSetText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withAlpha(((0.3) * 255).round())),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withAlpha(((0.7) * 255).round()),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              duration != null
                  ? "${duration!.inHours}h ${duration!.inMinutes % 60}m"
                  : notSetText,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
