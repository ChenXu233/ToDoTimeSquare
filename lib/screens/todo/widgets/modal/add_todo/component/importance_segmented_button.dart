import 'package:flutter/material.dart';
import '../../../../../../models/todo.dart';
import '../../../../../../i18n/i18n.dart';

class ImportanceSegmentedButton extends StatelessWidget {
  final TodoImportance importance;
  final ValueChanged<TodoImportance> onChanged;
  const ImportanceSegmentedButton({
    super.key,
    required this.importance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.importance,
          style: TextStyle(
            color: textColor.withAlpha(((0.7) * 255).round()),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TodoImportance>(
          segments: [
            ButtonSegment(value: TodoImportance.low, label: Text(i18n.low)),
            ButtonSegment(
              value: TodoImportance.medium,
              label: Text(i18n.medium),
            ),
            ButtonSegment(value: TodoImportance.high, label: Text(i18n.high)),
          ],
          selected: {importance},
          onSelectionChanged: (Set<TodoImportance> newSelection) {
            onChanged(newSelection.first);
          },
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onSecondaryContainer;
              }
              return textColor;
            }),
          ),
        ),
      ],
    );
  }
}
